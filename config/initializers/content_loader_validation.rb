Rails.application.config.after_initialize do
  ContentLoader.parts unless Rails.env.production?
end
