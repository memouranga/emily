require_relative "lib/emily/version"

Gem::Specification.new do |spec|
  spec.name        = "emily"
  spec.version     = Emily::VERSION
  spec.authors     = [ "9T Solutions" ]
  spec.email       = [ "hello@9t.solutions" ]
  spec.homepage    = "https://github.com/9tsolutions/emily"
  spec.summary     = "AI-powered sales & support chat engine for Rails"
  spec.description = "A mountable Rails engine that adds an AI chat widget to your app. Handles sales (lead qualification, product info) and support (knowledge base, ticket escalation) in a single unified interface. Powered by LLMs with RAG over your content."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/9tsolutions/emily"
  spec.metadata["changelog_uri"] = "https://github.com/9tsolutions/emily/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "ruby_llm"
end
