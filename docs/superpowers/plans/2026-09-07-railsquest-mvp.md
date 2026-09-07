# RailsQuest MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the RailsQuest MVP — a Rails 8 site that serves a Markdown-authored Rails course (parts 0-2 fully written, parts 3-7 as "coming soon" placeholders) with GitHub-OAuth accounts and per-exercise progress tracking.

**Architecture:** Course content (parts/chapters/exercises) lives as Markdown files with YAML front matter under `content/parts/`, parsed at request time by a plain-Ruby `ContentLoader` (no database). Two ActiveRecord models, `User` and `ExerciseCompletion`, back GitHub-OAuth login and per-exercise checkboxes. Controllers render content pages by reading from `ContentLoader`; a small Turbo Stream endpoint toggles exercise completion without a full page reload.

**Tech Stack:** Rails 8, SQLite (Solid Queue/Solid Cache defaults, unused by this MVP but left in place), Minitest + Capybara, Kramdown + Rouge for Markdown/syntax highlighting, omniauth-github for authentication.

**Spec:** `docs/superpowers/specs/2026-09-07-railsquest-design.md`

## Global Constraints

- Rails 8, SQLite, Minitest (no RSpec) — matches the author's other projects.
- Course content is never stored in the database; only `users` and `exercise_completions` are database-backed (spec §4).
- A malformed content file must fail the boot/test suite, never render a broken page in production (spec §7).
- No password-based auth, no email/password sign-up — GitHub OAuth only (spec §5).
- Parts 3-7 ship as "coming soon" placeholders with no chapters/exercises in the MVP (spec §3, §10).
- No exercise submission/grading, no quizzes, no admin content editor (spec §10 — out of scope).

---

## File Structure

```
app/
  models/
    user.rb
    exercise_completion.rb
    content/
      part.rb
      chapter.rb
      exercise.rb
  services/
    content_loader.rb
  controllers/
    application_controller.rb
    pages_controller.rb
    parts_controller.rb
    chapters_controller.rb
    sessions_controller.rb
    exercise_completions_controller.rb
    progress_controller.rb
  views/
    pages/home.html.erb
    parts/show.html.erb
    chapters/show.html.erb
    chapters/_exercise.html.erb
    progress/show.html.erb
    layouts/application.html.erb
content/
  parts/
    00-fondamentaux/
      part.yml
      01-mvc-et-conventions.md
      02-premiere-app.md
    01-modeles-activerecord/
      part.yml
      01-migrations-et-modeles.md
      02-associations-et-validations.md
    02-controleurs-vues-formulaires/
      part.yml
      01-routing-rest-et-crud.md
      02-formulaires-et-partials.md
    03-authentification-autorisation/part.yml
    04-tests/part.yml
    05-hotwire-turbo/part.yml
    06-jobs-emails/part.yml
    07-deploiement/part.yml
db/migrate/
  xxx_create_users.rb
  xxx_create_exercise_completions.rb
config/
  initializers/omniauth.rb
  routes.rb
test/
  fixtures/content/... (isolated fixture tree for ContentLoader tests, separate from content/)
  services/content_loader_test.rb
  models/exercise_completion_test.rb
  controllers/parts_controller_test.rb
  controllers/chapters_controller_test.rb
  controllers/exercise_completions_controller_test.rb
  system/course_journey_test.rb
```

---

### Task 1: Scaffold the Rails app

**Files:**
- Create: entire Rails 8 app skeleton in `/Users/rodolphe/code/dev/projects/railsquest` (via `rails new`)
- Modify: `Gemfile` (add `kramdown`, `rouge`, `omniauth-github`, `omniauth-rails_csrf_protection`)

**Interfaces:**
- Produces: a booting Rails 8 app with SQLite, Minitest, on which every later task depends.

- [ ] **Step 1: Generate the app in place**

The directory already contains `.git` and `docs/`. Run:

```bash
cd /Users/rodolphe/code/dev/projects/railsquest
rails new . --force --skip-git
```

`--skip-git` avoids re-initializing the repo that already exists; `--force` lets `rails new` overwrite the (currently empty) directory structure around the existing `docs/` folder.

- [ ] **Step 2: Add gems**

Add to `Gemfile`:

```ruby
gem "kramdown"
gem "rouge"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"
```

Run:

```bash
bundle install
```

- [ ] **Step 3: Verify the app boots**

```bash
bin/rails db:prepare
bin/rails runner 'puts "boot ok"'
```

Expected: prints `boot ok` with no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Scaffold Rails 8 app with content-rendering and auth gems"
```

---

### Task 2: Content value objects (`Content::Part`, `Content::Chapter`, `Content::Exercise`)

**Files:**
- Create: `app/models/content/exercise.rb`
- Create: `app/models/content/chapter.rb`
- Create: `app/models/content/part.rb`
- Test: `test/models/content/part_test.rb`

**Interfaces:**
- Produces: `Content::Exercise.new(key:, title:)`, `Content::Chapter.new(slug:, title:, exercises:, body_html:)` (`#exercises` returns an array of `Content::Exercise`), `Content::Part.new(number:, slug:, title:, status:, chapters:)` (`#chapters` returns an array of `Content::Chapter`, `#exercises` flattens all chapter exercises, `#written?` is true when `status == "written"`).
- Consumed by: `ContentLoader` (Task 3), all controllers/views from Task 6 onward.

- [ ] **Step 1: Write the failing test**

Create `test/models/content/part_test.rb`:

```ruby
require "test_helper"

class Content::PartTest < ActiveSupport::TestCase
  test "written? is true only when status is written" do
    written = Content::Part.new(number: 0, slug: "00-fondamentaux", title: "Fondamentaux",
                                 status: "written", chapters: [])
    coming_soon = Content::Part.new(number: 3, slug: "03-auth", title: "Auth",
                                     status: "coming_soon", chapters: [])

    assert written.written?
    assert_not coming_soon.written?
  end

  test "exercises flattens exercises across all chapters" do
    chapter_a = Content::Chapter.new(
      slug: "mvc", title: "MVC",
      exercises: [Content::Exercise.new(key: "0.1", title: "Installer Rails")],
      body_html: "<p>...</p>"
    )
    chapter_b = Content::Chapter.new(
      slug: "premiere-app", title: "Première app",
      exercises: [Content::Exercise.new(key: "0.2", title: "Explorer l'anatomie")],
      body_html: "<p>...</p>"
    )
    part = Content::Part.new(number: 0, slug: "00-fondamentaux", title: "Fondamentaux",
                              status: "written", chapters: [chapter_a, chapter_b])

    assert_equal ["0.1", "0.2"], part.exercises.map(&:key)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/content/part_test.rb`
Expected: FAIL — `uninitialized constant Content::Part` (or similar).

- [ ] **Step 3: Write minimal implementation**

Create `app/models/content/exercise.rb`:

```ruby
module Content
  Exercise = Struct.new(:key, :title, keyword_init: true)
end
```

Create `app/models/content/chapter.rb`:

```ruby
module Content
  class Chapter
    attr_reader :slug, :title, :exercises, :body_html

    def initialize(slug:, title:, exercises:, body_html:)
      @slug = slug
      @title = title
      @exercises = exercises
      @body_html = body_html
    end
  end
end
```

Create `app/models/content/part.rb`:

```ruby
module Content
  class Part
    attr_reader :number, :slug, :title, :status, :chapters

    def initialize(number:, slug:, title:, status:, chapters:)
      @number = number
      @slug = slug
      @title = title
      @status = status
      @chapters = chapters
    end

    def written?
      status == "written"
    end

    def exercises
      chapters.flat_map(&:exercises)
    end
  end
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/models/content/part_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 5: Commit**

```bash
git add app/models/content test/models/content
git commit -m "Add Content::Part/Chapter/Exercise value objects"
```

---

### Task 3: `ContentLoader` parsing

**Files:**
- Create: `app/services/content_loader.rb`
- Test: `test/services/content_loader_test.rb`
- Test fixtures: `test/fixtures/content/parts/00-sample-part/part.yml`, `test/fixtures/content/parts/00-sample-part/01-first-chapter.md`, `test/fixtures/content/parts/01-second-part/part.yml`

**Interfaces:**
- Consumes: `Content::Part`, `Content::Chapter`, `Content::Exercise` (Task 2).
- Produces: `ContentLoader.new(root:).parts` → array of `Content::Part` sorted by `number`. Raises `ContentLoader::InvalidContentError` on malformed content (wired up fully in Task 4).
- Consumed by: `ContentLoader.parts` class method (Task 4), controllers (Task 6+).

- [ ] **Step 1: Write fixture content**

Create `test/fixtures/content/parts/00-sample-part/part.yml`:

```yaml
number: 0
title: "Sample Part"
status: written
```

Create `test/fixtures/content/parts/00-sample-part/01-first-chapter.md`:

```markdown
---
title: "First Chapter"
exercises:
  - key: "0.1"
    title: "Do the first thing"
---

# First Chapter

Some **bold** text and a code block:

```ruby
puts "hello"
```
```

Create `test/fixtures/content/parts/01-second-part/part.yml`:

```yaml
number: 1
title: "Second Part"
status: coming_soon
```

- [ ] **Step 2: Write the failing test**

Create `test/services/content_loader_test.rb`:

```ruby
require "test_helper"

class ContentLoaderTest < ActiveSupport::TestCase
  def loader
    ContentLoader.new(root: Rails.root.join("test/fixtures/content/parts"))
  end

  test "parses parts sorted by number" do
    parts = loader.parts

    assert_equal [0, 1], parts.map(&:number)
    assert_equal ["Sample Part", "Second Part"], parts.map(&:title)
  end

  test "a part with no chapter files has an empty chapters list" do
    second_part = loader.parts.find { |p| p.number == 1 }

    assert_equal [], second_part.chapters
    assert_equal "coming_soon", second_part.status
  end

  test "parses chapter title, exercises and renders markdown body to HTML" do
    chapter = loader.parts.first.chapters.first

    assert_equal "First Chapter", chapter.title
    assert_equal [Content::Exercise.new(key: "0.1", title: "Do the first thing")], chapter.exercises
    assert_includes chapter.body_html, "<h1"
    assert_includes chapter.body_html, "<strong>bold</strong>"
    assert_includes chapter.body_html, "highlight"
  end

  test "chapter slug strips numeric prefix and extension" do
    chapter = loader.parts.first.chapters.first

    assert_equal "first-chapter", chapter.slug
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: FAIL — `uninitialized constant ContentLoader`.

- [ ] **Step 4: Write minimal implementation**

Create `app/services/content_loader.rb`:

```ruby
require "yaml"
require "kramdown"

class ContentLoader
  class InvalidContentError < StandardError; end

  def initialize(root:)
    @root = root
  end

  def parts
    Dir.children(@root).sort.map { |dirname| parse_part(@root.join(dirname)) }
              .sort_by(&:number)
  end

  private

  def parse_part(part_dir)
    meta = YAML.safe_load_file(part_dir.join("part.yml"))
    chapters = chapter_files(part_dir).map { |file| parse_chapter(file) }

    Content::Part.new(
      number: meta.fetch("number"),
      slug: File.basename(part_dir),
      title: meta.fetch("title"),
      status: meta.fetch("status"),
      chapters: chapters
    )
  end

  def chapter_files(part_dir)
    Dir.glob(part_dir.join("*.md")).sort
  end

  def parse_chapter(file_path)
    front_matter, body = split_front_matter(File.read(file_path))
    meta = YAML.safe_load(front_matter) || {}
    exercises = (meta["exercises"] || []).map do |ex|
      Content::Exercise.new(key: ex.fetch("key"), title: ex.fetch("title"))
    end

    Content::Chapter.new(
      slug: File.basename(file_path, ".md").sub(/\A\d+-/, ""),
      title: meta.fetch("title"),
      exercises: exercises,
      body_html: render_markdown(body)
    )
  end

  def split_front_matter(raw)
    return ["", raw] unless raw.start_with?("---")

    _, front_matter, body = raw.split(/^---\s*$/, 3)
    [front_matter, body]
  end

  def render_markdown(body)
    Kramdown::Document.new(body, input: "GFM", syntax_highlighter: "rouge").to_html
  end
end
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: PASS (5 runs, 0 failures).

- [ ] **Step 6: Commit**

```bash
git add app/services/content_loader.rb test/services/content_loader_test.rb test/fixtures/content
git commit -m "Add ContentLoader Markdown parsing"
```

---

### Task 4: `ContentLoader` validation and cached class-level access

**Files:**
- Modify: `app/services/content_loader.rb`
- Modify: `test/services/content_loader_test.rb`
- Test fixtures: `test/fixtures/invalid_content/parts/00-dup/part.yml`, `test/fixtures/invalid_content/parts/00-dup/01-a.md`, `test/fixtures/invalid_content/parts/00-dup/02-b.md` (two chapters reusing the same exercise key)

**Interfaces:**
- Produces: `ContentLoader.parts` (class method) — cached in production, uncached elsewhere, raising `ContentLoader::InvalidContentError` for bad content. `ContentLoader.new(root:).parts` still raises the same error (used directly by tests with custom roots).
- Consumed by: controllers (Task 6+), boot-time eager validation (Step 5 below).

- [ ] **Step 1: Write fixture content for the duplicate-key case**

Create `test/fixtures/invalid_content/parts/00-dup/part.yml`:

```yaml
number: 0
title: "Dup Part"
status: written
```

Create `test/fixtures/invalid_content/parts/00-dup/01-a.md`:

```markdown
---
title: "A"
exercises:
  - key: "0.1"
    title: "First"
---

# A
```

Create `test/fixtures/invalid_content/parts/00-dup/02-b.md`:

```markdown
---
title: "B"
exercises:
  - key: "0.1"
    title: "Duplicate key"
---

# B
```

- [ ] **Step 2: Write the failing tests**

Append to `test/services/content_loader_test.rb`:

```ruby
  test "raises InvalidContentError when exercise keys collide across chapters" do
    dup_loader = ContentLoader.new(root: Rails.root.join("test/fixtures/invalid_content/parts"))

    assert_raises(ContentLoader::InvalidContentError) { dup_loader.parts }
  end

  test "raises InvalidContentError when part status is not written or coming_soon" do
    Dir.mktmpdir do |dir|
      part_dir = Pathname.new(dir).join("00-bad-status")
      FileUtils.mkdir_p(part_dir)
      File.write(part_dir.join("part.yml"), { "number" => 0, "title" => "Bad", "status" => "draft" }.to_yaml)

      bad_loader = ContentLoader.new(root: Pathname.new(dir))

      assert_raises(ContentLoader::InvalidContentError) { bad_loader.parts }
    end
  end

  test "class method .parts delegates to the real content directory" do
    assert ContentLoader.parts.is_a?(Array)
    assert ContentLoader.parts.all? { |part| part.is_a?(Content::Part) }
  end
```

Add `require "tmpdir"` and `require "fileutils"` at the top of the test file if not already available (Minitest/Rails autoloads these; add explicitly for clarity):

```ruby
require "test_helper"
require "tmpdir"
require "fileutils"
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: the two new `InvalidContentError` tests FAIL (no validation yet); `.parts` class-method test FAILs with `NoMethodError`.

- [ ] **Step 4: Implement validation and the class method**

Modify `app/services/content_loader.rb` — replace the `parts` instance method and add validation plus the class method:

```ruby
require "yaml"
require "kramdown"

class ContentLoader
  class InvalidContentError < StandardError; end

  VALID_STATUSES = %w[written coming_soon].freeze

  def self.parts
    if Rails.env.production?
      Rails.cache.fetch("content_loader/parts/#{content_version}") { new(root: default_root).parts }
    else
      new(root: default_root).parts
    end
  end

  def self.default_root
    Rails.root.join("content", "parts")
  end

  def self.content_version
    Dir.glob(default_root.join("**/*")).map { |f| File.mtime(f).to_i }.max
  end

  def initialize(root:)
    @root = root
  end

  def parts
    parsed = Dir.children(@root).sort.map { |dirname| parse_part(@root.join(dirname)) }
    validate!(parsed)
    parsed.sort_by(&:number)
  end

  private

  def parse_part(part_dir)
    meta = YAML.safe_load_file(part_dir.join("part.yml"))
    chapters = chapter_files(part_dir).map { |file| parse_chapter(file) }

    Content::Part.new(
      number: meta.fetch("number"),
      slug: File.basename(part_dir),
      title: meta.fetch("title"),
      status: meta.fetch("status"),
      chapters: chapters
    )
  end

  def chapter_files(part_dir)
    Dir.glob(part_dir.join("*.md")).sort
  end

  def parse_chapter(file_path)
    front_matter, body = split_front_matter(File.read(file_path))
    meta = YAML.safe_load(front_matter) || {}
    exercises = (meta["exercises"] || []).map do |ex|
      Content::Exercise.new(key: ex.fetch("key"), title: ex.fetch("title"))
    end

    Content::Chapter.new(
      slug: File.basename(file_path, ".md").sub(/\A\d+-/, ""),
      title: meta.fetch("title"),
      exercises: exercises,
      body_html: render_markdown(body)
    )
  end

  def split_front_matter(raw)
    return ["", raw] unless raw.start_with?("---")

    _, front_matter, body = raw.split(/^---\s*$/, 3)
    [front_matter, body]
  end

  def render_markdown(body)
    Kramdown::Document.new(body, input: "GFM", syntax_highlighter: "rouge").to_html
  end

  def validate!(parts)
    parts.each do |part|
      unless VALID_STATUSES.include?(part.status)
        raise InvalidContentError, "part #{part.slug} has invalid status #{part.status.inspect}"
      end
    end

    numbers = parts.map(&:number)
    if numbers.uniq.length != numbers.length
      raise InvalidContentError, "duplicate part numbers: #{numbers}"
    end

    keys = parts.flat_map(&:exercises).map(&:key)
    if keys.uniq.length != keys.length
      duplicates = keys.tally.select { |_, count| count > 1 }.keys
      raise InvalidContentError, "duplicate exercise keys: #{duplicates}"
    end
  end
end
```

- [ ] **Step 5: Wire up boot-time validation**

Create `config/initializers/content_loader_validation.rb`:

```ruby
Rails.application.config.after_initialize do
  ContentLoader.parts unless Rails.env.production?
end
```

This makes a malformed chapter fail `bin/rails server`/`bin/rails test` startup immediately in development and test, per spec §7. Production skips eager validation at boot to avoid slow deploys re-parsing on every process start beyond the cached fetch already triggered by the first request.

- [ ] **Step 6: Create the real content directory**

`ContentLoader.parts` (the class method added in Step 4) reads from
`content/parts/`, which doesn't exist yet — Task 5 is the one that
populates it with real course parts, but the directory itself must exist
now for `Dir.children` to succeed instead of raising `Errno::ENOENT`.

```bash
mkdir -p content/parts
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: PASS (8 runs, 0 failures) — the `.parts` class-method test passes against the empty `content/parts/` directory (an empty array is still a valid, if uninteresting, result).

- [ ] **Step 8: Commit**

```bash
git add app/services/content_loader.rb test/services/content_loader_test.rb test/fixtures/invalid_content config/initializers/content_loader_validation.rb content/parts
git commit -m "Validate content at boot and cache ContentLoader.parts in production"
```

---

### Task 5: Placeholder parts 3-7 ("coming soon")

**Files:**
- Create: `content/parts/03-authentification-autorisation/part.yml`
- Create: `content/parts/04-tests/part.yml`
- Create: `content/parts/05-hotwire-turbo/part.yml`
- Create: `content/parts/06-jobs-emails/part.yml`
- Create: `content/parts/07-deploiement/part.yml`
- Test: `test/services/content_loader_test.rb` (extend to assert against real content)

**Interfaces:**
- Consumes: `ContentLoader.parts` (Task 4).
- Produces: real `content/parts/` entries for numbers 3-7, all `status: coming_soon`, no chapter files — satisfies the "8-part curriculum" from spec §3.

- [ ] **Step 1: Write the failing test**

Append to `test/services/content_loader_test.rb`:

```ruby
  test "the real course content has 8 parts, 3-7 coming soon with no chapters" do
    parts = ContentLoader.parts
    coming_soon = parts.select { |p| p.number.between?(3, 7) }

    assert_equal [3, 4, 5, 6, 7], coming_soon.map(&:number)
    assert coming_soon.all? { |p| p.status == "coming_soon" }
    assert coming_soon.all? { |p| p.chapters.empty? }
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: FAIL — parts 3-7 don't exist yet (empty array from `select`).

- [ ] **Step 3: Create the placeholder parts**

Create `content/parts/03-authentification-autorisation/part.yml`:

```yaml
number: 3
title: "Authentification & autorisation"
status: coming_soon
```

Create `content/parts/04-tests/part.yml`:

```yaml
number: 4
title: "Tests"
status: coming_soon
```

Create `content/parts/05-hotwire-turbo/part.yml`:

```yaml
number: 5
title: "Hotwire & Turbo"
status: coming_soon
```

Create `content/parts/06-jobs-emails/part.yml`:

```yaml
number: 6
title: "Jobs & emails"
status: coming_soon
```

Create `content/parts/07-deploiement/part.yml`:

```yaml
number: 7
title: "Déploiement"
status: coming_soon
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: PASS. (This test will start failing again once Task 6-8 add parts 0-2 with a different total; re-run the full suite after those tasks — no change needed here since this test only asserts on numbers 3-7.)

- [ ] **Step 5: Commit**

```bash
git add content/parts test/services/content_loader_test.rb
git commit -m "Add coming-soon placeholders for parts 3-7"
```

---

### Task 6: Home, part, and chapter pages

**Files:**
- Create: `app/controllers/pages_controller.rb`
- Create: `app/controllers/parts_controller.rb`
- Create: `app/controllers/chapters_controller.rb`
- Create: `app/views/pages/home.html.erb`
- Create: `app/views/parts/show.html.erb`
- Create: `app/views/chapters/show.html.erb`
- Modify: `config/routes.rb`
- Test: `test/controllers/pages_controller_test.rb`
- Test: `test/controllers/parts_controller_test.rb`
- Test: `test/controllers/chapters_controller_test.rb`

**Interfaces:**
- Consumes: `ContentLoader.parts`, `Content::Part#chapters`/`#written?`, `Content::Chapter#exercises`/`#body_html` (Tasks 2-4).
- Produces: `root_path` → home; `part_path(slug)` → part show; `part_chapter_path(part_slug, slug)` → chapter show. 404s (`ActiveRecord::RecordNotFound`-style via `raise ActionController::RoutingError`) for unknown slugs, consumed by Task 9/12's login-gated views which link into these pages.

This task's tests only exercise Task 5's placeholder parts (3-7, already on disk) for the "coming soon" and "404" cases. Run this task after Task 5; Tasks 7-9 later add real written-part content that these same views will render without further changes.

- [ ] **Step 1: Add routes**

Modify `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  root "pages#home"

  resources :parts, only: [:show], param: :slug do
    resources :chapters, only: [:show], param: :slug
  end
end
```

- [ ] **Step 2: Write the failing tests**

Create `test/controllers/pages_controller_test.rb`:

```ruby
require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home lists all 8 parts with their status" do
    get root_path

    assert_response :success
    assert_select "body", /Fondamentaux/
    assert_select "body", /Déploiement/
  end
end
```

Create `test/controllers/parts_controller_test.rb`:

```ruby
require "test_helper"

class PartsControllerTest < ActionDispatch::IntegrationTest
  test "show renders a coming-soon part with no chapters" do
    get part_path("07-deploiement")

    assert_response :success
    assert_select "body", /Déploiement/
    assert_select "body", /à venir|coming soon|bientôt/i
  end

  test "show 404s for an unknown part slug" do
    get part_path("99-does-not-exist")

    assert_response :not_found
  end
end
```

Create `test/controllers/chapters_controller_test.rb`:

```ruby
require "test_helper"

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  test "show 404s for an unknown chapter slug" do
    get part_chapter_path("07-deploiement", "does-not-exist")

    assert_response :not_found
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bin/rails test test/controllers/pages_controller_test.rb test/controllers/parts_controller_test.rb test/controllers/chapters_controller_test.rb`
Expected: FAIL — controllers/views don't exist yet.

- [ ] **Step 4: Implement controllers**

Create `app/controllers/pages_controller.rb`:

```ruby
class PagesController < ApplicationController
  def home
    @parts = ContentLoader.parts
  end
end
```

Create `app/controllers/parts_controller.rb`:

```ruby
class PartsController < ApplicationController
  def show
    @part = ContentLoader.parts.find { |part| part.slug == params[:slug] }
    raise ActionController::RoutingError, "Part not found" unless @part
  end
end
```

Create `app/controllers/chapters_controller.rb`:

```ruby
class ChaptersController < ApplicationController
  def show
    @part = ContentLoader.parts.find { |part| part.slug == params[:part_slug] }
    raise ActionController::RoutingError, "Part not found" unless @part

    @chapter = @part.chapters.find { |chapter| chapter.slug == params[:slug] }
    raise ActionController::RoutingError, "Chapter not found" unless @chapter
  end
end
```

`ActionController::RoutingError` is rescued by Rails as a 404 outside of the test environment by default; ensure tests see the same behavior by confirming `config.action_dispatch.show_exceptions` is not disabled for the test env's integration tests (Rails 8 default already returns 404 for this in `test` via `config.consider_all_requests_local = false` — no change needed).

- [ ] **Step 5: Implement views**

Create `app/views/pages/home.html.erb`:

```erb
<h1>RailsQuest</h1>
<p>Un cours Rails, inspiré de Full Stack Open, avec un fil rouge : un CRM de dons pour association.</p>

<ol>
  <% @parts.each do |part| %>
    <li>
      <%= link_to "Partie #{part.number} — #{part.title}", part_path(part.slug) %>
      <% unless part.written? %>
        <span>(à venir)</span>
      <% end %>
    </li>
  <% end %>
</ol>
```

Create `app/views/parts/show.html.erb`:

```erb
<h1>Partie <%= @part.number %> — <%= @part.title %></h1>

<% if @part.written? %>
  <ul>
    <% @part.chapters.each do |chapter| %>
      <li>
        <%= link_to chapter.title, part_chapter_path(@part.slug, chapter.slug) %>
        (<%= chapter.exercises.size %> exercice<%= "s" if chapter.exercises.size != 1 %>)
      </li>
    <% end %>
  </ul>
<% else %>
  <p>Cette partie est à venir.</p>
<% end %>

<%= link_to "Retour au sommaire", root_path %>
```

Create `app/views/chapters/show.html.erb`:

```erb
<h1><%= @chapter.title %></h1>

<%= raw @chapter.body_html %>

<h2>Exercices</h2>
<ul>
  <% @chapter.exercises.each do |exercise| %>
    <li><%= exercise.key %> — <%= exercise.title %></li>
  <% end %>
</ul>

<%= link_to "Retour à la partie", part_path(@part.slug) %>
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bin/rails test test/controllers/pages_controller_test.rb test/controllers/parts_controller_test.rb test/controllers/chapters_controller_test.rb`
Expected: PASS (4 runs, 0 failures).

- [ ] **Step 7: Commit**

```bash
git add app/controllers app/views config/routes.rb test/controllers
git commit -m "Add home, part and chapter pages"
```

---

### Task 7: Write Part 0 content — "Fondamentaux & philosophie Rails"

**Files:**
- Create: `content/parts/00-fondamentaux/part.yml`
- Create: `content/parts/00-fondamentaux/01-mvc-et-conventions.md`
- Create: `content/parts/00-fondamentaux/02-premiere-app.md`
- Test: extend `test/services/content_loader_test.rb`

**Interfaces:**
- Consumes: the `ContentLoader` front-matter schema (Tasks 3-4) — `title`, `exercises: [{key, title}]`.
- Produces: part number `0`, `status: written`, 2 chapters, exercise keys `0.1`, `0.2`, `0.3` — consumed by Task 6's rendered pages and Task 13's end-to-end test.

- [ ] **Step 1: Write the failing test**

Append to `test/services/content_loader_test.rb`:

```ruby
  test "part 0 is written with 2 chapters and 3 exercises" do
    part0 = ContentLoader.parts.find { |p| p.number == 0 }

    assert_equal "written", part0.status
    assert_equal 2, part0.chapters.size
    assert_equal ["0.1", "0.2", "0.3"], part0.exercises.map(&:key)
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: FAIL — part 0 doesn't exist yet.

- [ ] **Step 3: Write the content**

Create `content/parts/00-fondamentaux/part.yml`:

```yaml
number: 0
title: "Fondamentaux & philosophie Rails"
status: written
```

Create `content/parts/00-fondamentaux/01-mvc-et-conventions.md`:

```markdown
---
title: "MVC et convention over configuration"
exercises:
  - key: "0.1"
    title: "Installer Rails et générer un projet vide"
  - key: "0.2"
    title: "Repérer les 3 dossiers de app/ et dire à quoi chacun sert"
---

# MVC et convention over configuration

Rails organise toute application autour du patron **MVC** — Modèle, Vue,
Contrôleur — et d'un principe directeur : *convention over configuration*.
Plutôt que de configurer explicitement où se trouve chaque chose, Rails
impose des emplacements et des noms par défaut. Un fichier au bon endroit,
avec le bon nom, est automatiquement pris en compte.

Dans ce cours, on construit progressivement un **CRM de dons pour une
association** : des donateurs (`Donor`), des campagnes de collecte
(`Campaign`) et des dons (`Donation`). Chaque partie ajoute une couche à
cette application.

## Les trois rôles

- **Modèle** — représente les données et les règles métier (`Donor`,
  `Campaign`, `Donation`). Un modèle Rails hérite d'`ActiveRecord::Base`
  et correspond à une table de la base de données.
- **Vue** — ce que l'utilisateur voit : un template `.html.erb` qui mélange
  HTML et Ruby.
- **Contrôleur** — reçoit une requête HTTP, orchestre modèle(s) et vue,
  renvoie une réponse.

## Convention over configuration en pratique

Trois exemples que vous croiserez tout de suite :

```ruby
# app/models/donor.rb
class Donor < ApplicationRecord
end
```

Rails déduit que la table s'appelle `donors` (pluriel, snake_case) sans
qu'on l'écrive nulle part.

```ruby
# app/controllers/donors_controller.rb
class DonorsController < ApplicationController
  def index
    @donors = Donor.all
  end
end
```

L'action `index` cherche automatiquement la vue
`app/views/donors/index.html.erb` — encore une fois, aucune configuration.

```ruby
# config/routes.rb
resources :donors
```

Une seule ligne génère les 7 routes REST habituelles (`index`, `show`,
`new`, `create`, `edit`, `update`, `destroy`).

## Installer Rails

```bash
gem install rails
rails new donor_crm --database=sqlite3
cd donor_crm
bin/rails server
```

`bin/rails server` démarre un serveur de développement sur
`http://localhost:3000`.

## Exercices

**0.1 — Installer Rails et générer un projet vide**

Installez Rails, générez un projet nommé `donor_crm`, lancez-le et
vérifiez que la page d'accueil par défaut s'affiche dans votre navigateur.

**0.2 — Repérer les 3 dossiers de `app/`**

Ouvrez `app/models`, `app/views` et `app/controllers` dans le projet
généré. Pour chacun, écrivez une phrase expliquant à quoi il sert, dans un
fichier `NOTES.md` à la racine du projet.
```

Create `content/parts/00-fondamentaux/02-premiere-app.md`:

```markdown
---
title: "Anatomie d'une application générée"
exercises:
  - key: "0.3"
    title: "Modifier la page d'accueil par défaut"
---

# Anatomie d'une application générée

`rails new` génère une arborescence complète. Voici les dossiers que vous
utiliserez le plus dans ce cours :

- `app/` — le code de l'application (modèles, vues, contrôleurs, jobs,
  mailers...).
- `config/` — configuration, dont `config/routes.rb` qui définit les URLs
  de l'application.
- `db/` — les migrations (évolutions du schéma de base de données) et
  `db/schema.rb` (l'état courant du schéma).
- `test/` — les tests automatisés, écrits avec Minitest par défaut.

## `config/routes.rb`

C'est le point d'entrée de toute requête : Rails y cherche quelle
combinaison contrôleur/action doit traiter une URL donnée.

```ruby
Rails.application.routes.draw do
  root "pages#home"
end
```

Ici, une requête sur `/` est dirigée vers l'action `home` de
`PagesController`.

## Le serveur de développement

`bin/rails server` recharge automatiquement votre code à chaque requête en
développement — pas besoin de redémarrer le serveur après avoir modifié un
contrôleur ou une vue.

## Exercices

**0.3 — Modifier la page d'accueil par défaut**

Dans votre projet `donor_crm`, créez un contrôleur `PagesController` avec
une action `home`, une vue correspondante affichant "Bienvenue sur le CRM
de dons", et faites pointer `root` vers cette action dans
`config/routes.rb`. Vérifiez dans le navigateur.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add content/parts/00-fondamentaux test/services/content_loader_test.rb
git commit -m "Write Part 0 content: fondamentaux & philosophie Rails"
```

---

### Task 8: Write Part 1 content — "Modèles & ActiveRecord"

**Files:**
- Create: `content/parts/01-modeles-activerecord/part.yml`
- Create: `content/parts/01-modeles-activerecord/01-migrations-et-modeles.md`
- Create: `content/parts/01-modeles-activerecord/02-associations-et-validations.md`
- Test: extend `test/services/content_loader_test.rb`

**Interfaces:**
- Consumes: same `ContentLoader` front-matter schema as Task 7.
- Produces: part number `1`, `status: written`, 2 chapters, exercise keys `1.1`, `1.2`, `1.3`, `1.4`.

- [ ] **Step 1: Write the failing test**

Append to `test/services/content_loader_test.rb`:

```ruby
  test "part 1 is written with 2 chapters and 4 exercises" do
    part1 = ContentLoader.parts.find { |p| p.number == 1 }

    assert_equal "written", part1.status
    assert_equal 2, part1.chapters.size
    assert_equal ["1.1", "1.2", "1.3", "1.4"], part1.exercises.map(&:key)
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: FAIL — part 1 doesn't exist yet.

- [ ] **Step 3: Write the content**

Create `content/parts/01-modeles-activerecord/part.yml`:

```yaml
number: 1
title: "Modèles & ActiveRecord"
status: written
```

Create `content/parts/01-modeles-activerecord/01-migrations-et-modeles.md`:

```markdown
---
title: "Migrations et premiers modèles"
exercises:
  - key: "1.1"
    title: "Générer le modèle Donor avec une migration"
  - key: "1.2"
    title: "Ajouter des validations de présence sur Donor"
---

# Migrations et premiers modèles

Une **migration** décrit une évolution du schéma de base de données, sous
forme de code Ruby versionné. Rails applique les migrations dans l'ordre
et garde une trace de celles déjà exécutées.

## Générer un modèle

```bash
bin/rails generate model Donor name:string email:string
```

Cette commande crée trois fichiers : le modèle
`app/models/donor.rb`, une migration dans `db/migrate/`, et un fichier de
test `test/models/donor_test.rb`.

La migration générée ressemble à :

```ruby
class CreateDonors < ActiveRecord::Migration[8.0]
  def change
    create_table :donors do |t|
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
```

`t.timestamps` ajoute automatiquement `created_at` et `updated_at`,
maintenues par Rails.

```bash
bin/rails db:migrate
```

applique la migration et met à jour `db/schema.rb`.

## Validations

```ruby
class Donor < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true
end
```

`validates` empêche `save` de réussir si la condition n'est pas remplie —
`donor.save` renvoie alors `false` et `donor.errors` contient le détail.

## La console Rails

```bash
bin/rails console
```

ouvre un IRB avec l'application chargée : idéal pour explorer les modèles
sans passer par le navigateur.

```ruby
Donor.create(name: "Alice", email: "alice@example.org")
Donor.count
Donor.first.name
```

## Exercices

**1.1 — Générer le modèle Donor avec une migration**

Dans `donor_crm`, générez un modèle `Donor` avec les champs `name:string`
et `email:string`, migrez la base, puis créez un donateur depuis la
console Rails.

**1.2 — Ajouter des validations de présence sur `Donor`**

Ajoutez des validations de présence sur `name` et `email`. Depuis la
console, vérifiez que `Donor.new.save` renvoie `false` et que
`Donor.new.errors.full_messages` liste les deux erreurs.
```

Create `content/parts/01-modeles-activerecord/02-associations-et-validations.md`:

```markdown
---
title: "Associations entre modèles"
exercises:
  - key: "1.3"
    title: "Générer Campaign et Donation avec leurs associations"
  - key: "1.4"
    title: "Calculer le total collecté sur une campagne"
---

# Associations entre modèles

Notre CRM a trois entités liées : un donateur fait des dons, chaque don
est rattaché à une campagne.

```bash
bin/rails generate model Campaign name:string goal_cents:integer
bin/rails generate model Donation amount_cents:integer donor:references campaign:references
bin/rails db:migrate
```

`donor:references` ajoute une colonne `donor_id` et un index, et génère
automatiquement `belongs_to :donor` dans `Donation`.

## Déclarer les associations

```ruby
# app/models/donor.rb
class Donor < ApplicationRecord
  has_many :donations
end
```

```ruby
# app/models/campaign.rb
class Campaign < ApplicationRecord
  has_many :donations
end
```

```ruby
# app/models/donation.rb
class Donation < ApplicationRecord
  belongs_to :donor
  belongs_to :campaign
  validates :amount_cents, numericality: { greater_than: 0 }
end
```

`belongs_to` est obligatoire par défaut dans Rails : une `Donation` sans
`donor_id` ni `campaign_id` échouera à la validation.

## Naviguer les associations

```ruby
donor = Donor.first
donor.donations              # toutes les donations de ce donateur
donor.donations.sum(:amount_cents)

campaign = Campaign.first
campaign.donations.count
```

## Exercices

**1.3 — Générer `Campaign` et `Donation` avec leurs associations**

Générez les deux modèles comme ci-dessus, migrez, puis déclarez
`has_many`/`belongs_to` sur les trois modèles. Depuis la console, créez une
campagne, un donateur, et un don qui les relie.

**1.4 — Calculer le total collecté sur une campagne**

Ajoutez une méthode d'instance `total_collected_cents` sur `Campaign` qui
retourne la somme de `amount_cents` de ses dons. Vérifiez le résultat
depuis la console avec plusieurs dons.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add content/parts/01-modeles-activerecord test/services/content_loader_test.rb
git commit -m "Write Part 1 content: modèles & ActiveRecord"
```

---

### Task 9: Write Part 2 content — "Contrôleurs, vues & formulaires"

**Files:**
- Create: `content/parts/02-controleurs-vues-formulaires/part.yml`
- Create: `content/parts/02-controleurs-vues-formulaires/01-routing-rest-et-crud.md`
- Create: `content/parts/02-controleurs-vues-formulaires/02-formulaires-et-partials.md`
- Test: extend `test/services/content_loader_test.rb`

**Interfaces:**
- Consumes: same `ContentLoader` front-matter schema as Tasks 7-8.
- Produces: part number `2`, `status: written`, 2 chapters, exercise keys `2.1`, `2.2`, `2.3`.

- [ ] **Step 1: Write the failing test**

Append to `test/services/content_loader_test.rb`:

```ruby
  test "part 2 is written with 2 chapters and 3 exercises" do
    part2 = ContentLoader.parts.find { |p| p.number == 2 }

    assert_equal "written", part2.status
    assert_equal 2, part2.chapters.size
    assert_equal ["2.1", "2.2", "2.3"], part2.exercises.map(&:key)
  end

  test "all written parts together expose 10 exercises with globally unique keys" do
    all_keys = ContentLoader.parts.flat_map(&:exercises).map(&:key)

    assert_equal 10, all_keys.size
    assert_equal all_keys, all_keys.uniq
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: FAIL — part 2 doesn't exist yet.

- [ ] **Step 3: Write the content**

Create `content/parts/02-controleurs-vues-formulaires/part.yml`:

```yaml
number: 2
title: "Contrôleurs, vues & formulaires"
status: written
```

Create `content/parts/02-controleurs-vues-formulaires/01-routing-rest-et-crud.md`:

```markdown
---
title: "Routing REST et CRUD complet"
exercises:
  - key: "2.1"
    title: "Générer le contrôleur Donors avec les 7 actions REST"
  - key: "2.2"
    title: "Ajouter la suppression d'un donateur"
---

# Routing REST et CRUD complet

`resources :donors` dans `config/routes.rb` génère 7 routes correspondant
aux opérations CRUD (Create, Read, Update, Delete) :

| Verbe HTTP | URL | Action | Usage |
|---|---|---|---|
| GET | `/donors` | `index` | Liste des donateurs |
| GET | `/donors/new` | `new` | Formulaire de création |
| POST | `/donors` | `create` | Traite la soumission |
| GET | `/donors/:id` | `show` | Fiche d'un donateur |
| GET | `/donors/:id/edit` | `edit` | Formulaire d'édition |
| PATCH | `/donors/:id` | `update` | Traite la modification |
| DELETE | `/donors/:id` | `destroy` | Supprime |

## Le contrôleur

```ruby
class DonorsController < ApplicationController
  def index
    @donors = Donor.all
  end

  def show
    @donor = Donor.find(params[:id])
  end

  def new
    @donor = Donor.new
  end

  def create
    @donor = Donor.new(donor_params)
    if @donor.save
      redirect_to @donor, notice: "Donateur créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @donor = Donor.find(params[:id])
  end

  def update
    @donor = Donor.find(params[:id])
    if @donor.update(donor_params)
      redirect_to @donor, notice: "Donateur mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def donor_params
    params.require(:donor).permit(:name, :email)
  end
end
```

`donor_params` illustre les **strong parameters** : Rails refuse par
défaut d'assigner en masse des attributs non explicitement autorisés,
pour éviter qu'un client malveillant n'écrive des colonnes non prévues.

## Exercices

**2.1 — Générer le contrôleur `Donors` avec les 7 actions REST**

Dans `donor_crm`, ajoutez `resources :donors` aux routes, créez
`DonorsController` avec `index`, `show`, `new`, `create`, `edit`, `update`
comme ci-dessus, et les vues `index.html.erb`/`show.html.erb`
correspondantes (une simple liste et une fiche suffisent). Vérifiez que
créer un donateur via le formulaire fonctionne.

**2.2 — Ajouter la suppression d'un donateur**

Ajoutez l'action `destroy` au contrôleur et un bouton de suppression sur
la page `show`, avec `button_to "Supprimer", @donor, method: :delete`.
```

Create `content/parts/02-controleurs-vues-formulaires/02-formulaires-et-partials.md`:

```markdown
---
title: "Formulaires, partials et flash"
exercises:
  - key: "2.3"
    title: "Factoriser le formulaire de Donor en partial"
---

# Formulaires, partials et flash

## `form_with`

```erb
<%= form_with model: @donor do |f| %>
  <%= f.label :name %>
  <%= f.text_field :name %>

  <%= f.label :email %>
  <%= f.email_field :email %>

  <%= f.submit %>
<% end %>
```

`form_with model: @donor` déduit automatiquement l'URL et la méthode HTTP
(POST vers `/donors` si `@donor` est nouveau, PATCH vers `/donors/:id`
sinon) — encore *convention over configuration*.

## Partials

`new.html.erb` et `edit.html.erb` ont presque toujours le même contenu :
le formulaire. On factorise avec un partial `_form.html.erb` :

```erb
<%# app/views/donors/_form.html.erb %>
<%= form_with model: donor do |f| %>
  <%= f.label :name %>
  <%= f.text_field :name %>

  <%= f.label :email %>
  <%= f.email_field :email %>

  <%= f.submit %>
<% end %>
```

```erb
<%# app/views/donors/new.html.erb %>
<h1>Nouveau donateur</h1>
<%= render "form", donor: @donor %>
```

```erb
<%# app/views/donors/edit.html.erb %>
<h1>Modifier le donateur</h1>
<%= render "form", donor: @donor %>
```

## Flash messages

`redirect_to @donor, notice: "Donateur créé."` stocke le message dans
`flash[:notice]`, disponible sur la prochaine requête seulement. Il faut
l'afficher dans le layout :

```erb
<%# app/views/layouts/application.html.erb, dans <body> %>
<% if notice %>
  <p class="flash-notice"><%= notice %></p>
<% end %>
```

## Exercices

**2.3 — Factoriser le formulaire de `Donor` en partial**

Dans `donor_crm`, extrayez le formulaire de `new.html.erb` dans un partial
`_form.html.erb` réutilisé par `new.html.erb` et `edit.html.erb`. Ajoutez
l'affichage du flash dans le layout et vérifiez qu'un message apparaît
après création et après modification.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bin/rails test test/services/content_loader_test.rb`
Expected: PASS (all ContentLoader tests, including the "10 globally unique keys" test).

- [ ] **Step 5: Commit**

```bash
git add content/parts/02-controleurs-vues-formulaires test/services/content_loader_test.rb
git commit -m "Write Part 2 content: contrôleurs, vues & formulaires"
```

---

### Task 10: `User` model and GitHub OAuth login

**Files:**
- Create: `db/migrate/xxxxxxxxxxxxxx_create_users.rb`
- Create: `app/models/user.rb`
- Create: `app/controllers/sessions_controller.rb`
- Create: `config/initializers/omniauth.rb`
- Modify: `app/controllers/application_controller.rb`
- Modify: `config/routes.rb`
- Modify: `app/views/layouts/application.html.erb` (login/logout link)
- Test: `test/models/user_test.rb`
- Test: `test/controllers/sessions_controller_test.rb`

**Interfaces:**
- Produces: `User.find_or_create_from_omniauth(auth_hash)` (class method, returns a persisted `User`); `ApplicationController#current_user` (returns `User` or `nil`), `#logged_in?`.
- Consumed by: `ExerciseCompletionsController` and `ProgressController` (Tasks 11-12), the layout, and the system test (Task 13).

- [ ] **Step 1: Generate and inspect the migration**

```bash
bin/rails generate model User github_id:string:uniq username:string avatar_url:string
```

Open the generated migration under `db/migrate/` and confirm it matches:

```ruby
class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :github_id
      t.string :username
      t.string :avatar_url

      t.timestamps
    end
    add_index :users, :github_id, unique: true
  end
end
```

If the generator did not add the unique index (depends on Rails version
handling of the `:uniq` modifier), edit the migration to add
`add_index :users, :github_id, unique: true` explicitly.

Run:

```bash
bin/rails db:migrate
```

- [ ] **Step 2: Write the failing model test**

Create `test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "find_or_create_from_omniauth creates a new user on first login" do
    auth = OmniAuth::AuthHash.new(
      uid: "12345",
      info: { nickname: "octocat", image: "https://example.org/avatar.png" }
    )

    assert_difference "User.count", 1 do
      user = User.find_or_create_from_omniauth(auth)

      assert_equal "12345", user.github_id
      assert_equal "octocat", user.username
      assert_equal "https://example.org/avatar.png", user.avatar_url
    end
  end

  test "find_or_create_from_omniauth returns the existing user on repeat login" do
    auth = OmniAuth::AuthHash.new(uid: "12345", info: { nickname: "octocat", image: "https://example.org/a.png" })
    first = User.find_or_create_from_omniauth(auth)

    assert_no_difference "User.count" do
      second = User.find_or_create_from_omniauth(auth)
      assert_equal first.id, second.id
    end
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bin/rails test test/models/user_test.rb`
Expected: FAIL — `NoMethodError: undefined method 'find_or_create_from_omniauth'`.

- [ ] **Step 4: Implement `User`**

Create `app/models/user.rb`:

```ruby
class User < ApplicationRecord
  has_many :exercise_completions, dependent: :destroy

  def self.find_or_create_from_omniauth(auth)
    find_or_create_by!(github_id: auth.uid) do |user|
      user.username = auth.info.nickname
      user.avatar_url = auth.info.image
    end
  end
end
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bin/rails test test/models/user_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 6: Configure OmniAuth**

Create `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github,
    Rails.application.credentials.dig(:github, :client_id),
    Rails.application.credentials.dig(:github, :client_secret)
end

OmniAuth.config.allowed_request_methods = [:post]
```

Add routes to `config/routes.rb` (inside `Rails.application.routes.draw do ... end`, alongside existing routes):

```ruby
  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy"
```

- [ ] **Step 7: Add `current_user` to `ApplicationController`**

Modify `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    redirect_to root_path, alert: "Connectez-vous pour continuer." unless logged_in?
  end
end
```

- [ ] **Step 8: Write the failing controller test**

Create `test/controllers/sessions_controller_test.rb`:

```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      uid: "99999", info: { nickname: "hubot", image: "https://example.org/hubot.png" }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "create logs the user in and redirects home" do
    get "/auth/github/callback"

    assert_redirected_to root_path
    follow_redirect!
    assert_select "body", /hubot/
  end

  test "destroy logs the user out" do
    get "/auth/github/callback"
    delete "/logout"

    follow_redirect!
    assert_select "a", "Se connecter avec GitHub"
  end
end
```

- [ ] **Step 9: Run test to verify it fails**

Run: `bin/rails test test/controllers/sessions_controller_test.rb`
Expected: FAIL — `SessionsController` doesn't exist.

- [ ] **Step 10: Implement `SessionsController`**

Create `app/controllers/sessions_controller.rb`:

```ruby
class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_omniauth(auth)
    session[:user_id] = user.id
    redirect_to root_path, notice: "Connecté."
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Déconnecté."
  end

  def failure
    redirect_to root_path, alert: "Échec de la connexion GitHub."
  end
end
```

- [ ] **Step 11: Add login/logout links to the layout**

Modify `app/views/layouts/application.html.erb`, inside `<body>` near the
top:

```erb
<nav>
  <% if logged_in? %>
    <span><%= current_user.username %></span>
    <%= button_to "Se déconnecter", logout_path, method: :delete %>
  <% else %>
    <%= button_to "Se connecter avec GitHub", "/auth/github", method: :post, data: { turbo: false } %>
  <% end %>
</nav>

<% if notice %>
  <p class="flash-notice"><%= notice %></p>
<% end %>
<% if alert %>
  <p class="flash-alert"><%= alert %></p>
<% end %>
```

`button_to ... method: :post` matches `omniauth-rails_csrf_protection`'s
requirement that the initial `/auth/github` request be a POST carrying the
Rails CSRF token; `data: { turbo: false }` ensures a full page navigation
into the OmniAuth redirect flow rather than a Turbo-intercepted fetch.

- [ ] **Step 12: Run tests to verify they pass**

Run: `bin/rails test test/controllers/sessions_controller_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 13: Commit**

```bash
git add db/migrate app/models/user.rb app/controllers/sessions_controller.rb \
  config/initializers/omniauth.rb app/controllers/application_controller.rb \
  config/routes.rb app/views/layouts/application.html.erb \
  test/models/user_test.rb test/controllers/sessions_controller_test.rb
git commit -m "Add User model and GitHub OAuth login"
```

---

### Task 11: `ExerciseCompletion` model and toggle endpoint

**Files:**
- Create: `db/migrate/xxxxxxxxxxxxxx_create_exercise_completions.rb`
- Create: `app/models/exercise_completion.rb`
- Create: `app/controllers/exercise_completions_controller.rb`
- Create: `app/views/chapters/_exercise.html.erb`
- Modify: `app/views/chapters/show.html.erb`
- Modify: `config/routes.rb`
- Test: `test/models/exercise_completion_test.rb`
- Test: `test/controllers/exercise_completions_controller_test.rb`

**Interfaces:**
- Consumes: `current_user`/`require_login` (Task 10), `Content::Exercise#key` (Task 2).
- Produces: `User#completed?(exercise_key)` (used by the progress page, Task 12), `exercise_completions_path` (POST toggles a completion on/off).

- [ ] **Step 1: Generate and inspect the migration**

```bash
bin/rails generate model ExerciseCompletion user:references exercise_key:string
```

Open the generated migration and add a uniqueness index:

```ruby
class CreateExerciseCompletions < ActiveRecord::Migration[8.0]
  def change
    create_table :exercise_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :exercise_key, null: false

      t.timestamps
    end
    add_index :exercise_completions, [:user_id, :exercise_key], unique: true
  end
end
```

Run:

```bash
bin/rails db:migrate
```

- [ ] **Step 2: Write the failing model test**

Create `test/models/exercise_completion_test.rb`:

```ruby
require "test_helper"

class ExerciseCompletionTest < ActiveSupport::TestCase
  test "a user cannot complete the same exercise twice" do
    user = User.create!(github_id: "1", username: "alice")
    user.exercise_completions.create!(exercise_key: "0.1")

    duplicate = user.exercise_completions.build(exercise_key: "0.1")

    assert_not duplicate.valid?
  end

  test "User#completed? reflects whether an exercise has been marked done" do
    user = User.create!(github_id: "2", username: "bob")

    assert_not user.completed?("0.1")

    user.exercise_completions.create!(exercise_key: "0.1")

    assert user.completed?("0.1")
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bin/rails test test/models/exercise_completion_test.rb`
Expected: FAIL — no uniqueness validation, no `User#completed?`.

- [ ] **Step 4: Implement `ExerciseCompletion` and `User#completed?`**

Create `app/models/exercise_completion.rb`:

```ruby
class ExerciseCompletion < ApplicationRecord
  belongs_to :user
  validates :exercise_key, presence: true, uniqueness: { scope: :user_id }
end
```

Modify `app/models/user.rb` — add inside the class:

```ruby
  def completed?(exercise_key)
    exercise_completions.exists?(exercise_key: exercise_key)
  end
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bin/rails test test/models/exercise_completion_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 6: Add the routes**

Exercise keys contain dots (e.g. `"0.1"`), so the `destroy` route needs an
explicit constraint — Rails' default `:id`-style segment matcher excludes
dots (it treats a trailing dot as a format suffix), which would otherwise
truncate `"0.1"` down to `"0"`.

Modify `config/routes.rb`, add alongside existing routes:

```ruby
  resources :exercise_completions, only: [:create]
  delete "/exercise_completions/:exercise_key", to: "exercise_completions#destroy",
    as: :exercise_completion, constraints: { exercise_key: /[^\/]+/ }
```

- [ ] **Step 7: Write the failing controller test**

Create `test/controllers/exercise_completions_controller_test.rb`:

```ruby
require "test_helper"

class ExerciseCompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(github_id: "1", username: "alice")
  end

  test "create requires login" do
    post exercise_completions_path, params: { exercise_key: "0.1" }

    assert_redirected_to root_path
  end

  test "create marks the exercise done for the logged-in user" do
    sign_in_as(@user)

    assert_difference "@user.exercise_completions.count", 1 do
      post exercise_completions_path, params: { exercise_key: "0.1" }
      @user.reload
    end
    assert_response :success
  end

  test "destroy un-marks the exercise for the logged-in user" do
    sign_in_as(@user)
    @user.exercise_completions.create!(exercise_key: "0.1")

    assert_difference "@user.exercise_completions.count", -1 do
      delete exercise_completion_path("0.1")
      @user.reload
    end
    assert_response :success
  end

  private

  def sign_in_as(user)
    post "/session_for_test", params: { user_id: user.id }
  end
end
```

This test needs a way to log a user in without going through the real
GitHub OAuth redirect. Add a test-only session route and controller
action.

Modify `config/routes.rb`, add:

```ruby
  post "/session_for_test", to: "sessions#create_for_test" if Rails.env.test?
```

Modify `app/controllers/sessions_controller.rb`, add:

```ruby
  def create_for_test
    session[:user_id] = params[:user_id]
    head :ok
  end
```

- [ ] **Step 8: Run tests to verify they fail**

Run: `bin/rails test test/controllers/exercise_completions_controller_test.rb`
Expected: FAIL — `ExerciseCompletionsController` doesn't exist.

- [ ] **Step 9: Implement `ExerciseCompletionsController`**

Create `app/controllers/exercise_completions_controller.rb`:

```ruby
class ExerciseCompletionsController < ApplicationController
  before_action :require_login

  def create
    current_user.exercise_completions.find_or_create_by!(exercise_key: params[:exercise_key])
    render_exercise_state(params[:exercise_key], completed: true)
  end

  def destroy
    current_user.exercise_completions.find_by(exercise_key: params[:exercise_key])&.destroy
    render_exercise_state(params[:exercise_key], completed: false)
  end

  private

  def render_exercise_state(exercise_key, completed:)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "exercise_#{exercise_key.parameterize}",
          partial: "chapters/exercise",
          locals: { exercise_key: exercise_key, completed: completed }
        )
      end
      format.html { head :ok }
    end
  end
end
```

- [ ] **Step 10: Build the exercise partial and wire it into the chapter view**

The partial takes plain locals (`exercise_key`, `exercise_title`,
`completed`) rather than a `Content::Exercise` object, because the
controller's `turbo_stream.replace` call (Step 9) only has a bare
`exercise_key` string to work with after a toggle — it doesn't have
the original chapter loaded. Using the same locals for the initial
chapter render (Step 10 below) keeps one partial for both cases.

Create `app/views/chapters/_exercise.html.erb`:

```erb
<li id="exercise_<%= exercise_key.parameterize %>">
  <% if logged_in? %>
    <%= button_to(completed ? "Décocher" : "Marquer comme fait",
          completed ? exercise_completion_path(exercise_key) : exercise_completions_path,
          method: completed ? :delete : :post,
          params: completed ? {} : { exercise_key: exercise_key }) %>
  <% end %>
  <%= exercise_key %> — <%= exercise_title %>
</li>
```

Modify `app/views/chapters/show.html.erb`, replace the exercises `<ul>`
block with:

```erb
<h2>Exercices</h2>
<ul>
  <% @chapter.exercises.each do |exercise| %>
    <%= render "chapters/exercise",
          exercise_key: exercise.key,
          exercise_title: exercise.title,
          completed: logged_in? && current_user.completed?(exercise.key) %>
  <% end %>
</ul>
```

- [ ] **Step 11: Run tests to verify they pass**

Run: `bin/rails test test/controllers/exercise_completions_controller_test.rb`
Expected: PASS (3 runs, 0 failures).

- [ ] **Step 12: Run the full test suite**

Run: `bin/rails test`
Expected: all tests pass — this catches any regression in the chapter
view from the partial rewrite.

- [ ] **Step 13: Commit**

```bash
git add db/migrate app/models/exercise_completion.rb app/models/user.rb \
  app/controllers/exercise_completions_controller.rb app/controllers/sessions_controller.rb \
  app/views/chapters config/routes.rb \
  test/models/exercise_completion_test.rb test/controllers/exercise_completions_controller_test.rb
git commit -m "Add exercise completion toggling via Turbo Stream"
```

---

### Task 12: Progress page

**Files:**
- Create: `app/controllers/progress_controller.rb`
- Create: `app/views/progress/show.html.erb`
- Modify: `config/routes.rb`
- Modify: `app/views/layouts/application.html.erb` (nav link, only when logged in)
- Test: `test/controllers/progress_controller_test.rb`

**Interfaces:**
- Consumes: `ContentLoader.parts`, `Content::Part#exercises`/`#written?` (Tasks 2-4), `current_user`/`require_login` (Task 10), `User#completed?` (Task 11).
- Produces: `progress_path` — a page showing "X/Y exercices faits" per written part plus a global total.

- [ ] **Step 1: Add the route**

Modify `config/routes.rb`, add:

```ruby
  resource :progress, only: [:show], controller: "progress"
```

- [ ] **Step 2: Write the failing test**

Create `test/controllers/progress_controller_test.rb`:

```ruby
require "test_helper"

class ProgressControllerTest < ActionDispatch::IntegrationTest
  test "requires login" do
    get progress_path

    assert_redirected_to root_path
  end

  test "shows per-part and total progress for the logged-in user" do
    user = User.create!(github_id: "1", username: "alice")
    post "/session_for_test", params: { user_id: user.id }
    user.exercise_completions.create!(exercise_key: "0.1")

    get progress_path

    assert_response :success
    assert_select "body", /1\s*\/\s*10/
  end
end
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bin/rails test test/controllers/progress_controller_test.rb`
Expected: FAIL — `ProgressController` doesn't exist.

- [ ] **Step 4: Implement `ProgressController`**

Create `app/controllers/progress_controller.rb`:

```ruby
class ProgressController < ApplicationController
  before_action :require_login

  def show
    @parts = ContentLoader.parts.select(&:written?)
    @completed_keys = current_user.exercise_completions.pluck(:exercise_key)
  end
end
```

- [ ] **Step 5: Implement the view**

Create `app/views/progress/show.html.erb`:

```erb
<h1>Votre progression</h1>

<% total_exercises = @parts.flat_map(&:exercises) %>
<% total_completed = total_exercises.count { |ex| @completed_keys.include?(ex.key) } %>

<p>Total : <%= total_completed %> / <%= total_exercises.size %></p>

<ul>
  <% @parts.each do |part| %>
    <% part_completed = part.exercises.count { |ex| @completed_keys.include?(ex.key) } %>
    <li>
      Partie <%= part.number %> — <%= part.title %> :
      <%= part_completed %> / <%= part.exercises.size %>
    </li>
  <% end %>
</ul>

<%= link_to "Retour au sommaire", root_path %>
```

- [ ] **Step 6: Add a nav link when logged in**

Modify `app/views/layouts/application.html.erb`, inside the `<% if
logged_in? %>` branch added in Task 10, before the logout button:

```erb
    <%= link_to "Ma progression", progress_path %>
```

- [ ] **Step 7: Run test to verify it passes**

Run: `bin/rails test test/controllers/progress_controller_test.rb`
Expected: PASS (2 runs, 0 failures).

- [ ] **Step 8: Commit**

```bash
git add app/controllers/progress_controller.rb app/views/progress app/views/layouts/application.html.erb \
  config/routes.rb test/controllers/progress_controller_test.rb
git commit -m "Add progress tracking page"
```

---

### Task 13: End-to-end system test

**Files:**
- Test: `test/system/course_journey_test.rb`

**Interfaces:**
- Consumes: every controller/view/model from Tasks 6-12, plus the real content from Tasks 7-9.
- Produces: a regression guard for the full user journey described in spec §8.

- [ ] **Step 1: Write the system test**

Create `test/system/course_journey_test.rb`:

```ruby
require "application_system_test_case"

class CourseJourneyTest < ApplicationSystemTestCase
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      uid: "42", info: { nickname: "learner", image: "https://example.org/learner.png" }
    )
  end

  teardown do
    OmniAuth.config.mock_auth[:github] = nil
  end

  test "a visitor logs in, reads a chapter, checks an exercise, and sees progress update" do
    visit root_path
    click_on "Se connecter avec GitHub"

    assert_text "learner"

    click_on "Partie 0"
    click_on "MVC et convention over configuration"

    assert_text "Convention over configuration en pratique"

    within "#exercise_0-1" do
      click_on "Marquer comme fait"
    end

    within "#exercise_0-1" do
      assert_text "Décocher"
    end

    click_on "Ma progression"

    assert_text "1 / 10"
  end
end
```

- [ ] **Step 2: Run the test to verify it fails first for the right reason, then passes**

Run: `bin/rails test:system test/system/course_journey_test.rb`

If it fails, inspect the failure message against the views built in
Tasks 6-12 (common culprits: the home page link text doesn't start with
"Partie 0" exactly, or the exercise `id` doesn't match
`exercise_0-1`). Fix the view text or the test's selector to match
reality — do not change the underlying behavior to fit the test.

Expected once green: PASS (1 run, 0 failures).

- [ ] **Step 3: Run the entire suite**

Run: `bin/rails test && bin/rails test:system`
Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/system/course_journey_test.rb
git commit -m "Add end-to-end system test for the core learning journey"
```

---

## Post-plan notes (not tasks — context for whoever picks this up)

- GitHub OAuth needs real credentials before the login button works outside tests: `bin/rails credentials:edit` and add `github.client_id` / `github.client_secret` from a GitHub OAuth App (callback URL `http://localhost:3000/auth/github/callback` in development).
- Deployment (Kamal, production `client_id`/`client_secret`, HTTPS callback URL) is out of scope per spec §10 and not covered by this plan.
