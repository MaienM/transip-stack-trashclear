#!/usr/bin/env ruby

require 'net/http'
require 'bundler'
Bundler.require

def usage
	puts "Usage: $0 [env file]"
	puts
	puts "env file is a file with the following environment variables:"
	puts "  STACK_URL: the url of your stack"
	puts "  STACK_USERNAME: the username to login with"
	puts "  STACK_PASSWORD: the password to login with"
	puts "  STACK_USER_AGENT: the user-agent to use (optional)"
	puts "if no env file is passed, .env is used, the variables that already"
	puts "exists in the environment are used"
	exit 1
end

# Load the environment file
Dotenv.load(ARGV[0] || '.env')
STACK_URL = ENV['STACK_URL']
STACK_USERNAME = ENV['STACK_USERNAME']
STACK_PASSWORD = ENV['STACK_PASSWORD']

# Check the environment variables
abort('STACK_URL needs to start with https://') unless STACK_URL.starts_with?('https://')
abort('STACK_USERNAME cannot be empty') if STACK_USERNAME.empty?
abort('STACK_PASSWORD cannot be empty') if STACK_PASSWORD.empty?

module HTTP
	# Use nokogiri to parse HTML pages
	module MimeType
		class HTML < Adapter
			def decode(str)
				return ::Nokogiri::HTML(str)
			end
		end

		register_adapter "text/html", HTML
		register_alias   "text/html", :html
	end

	# Convenience methods
	class Response
		def valid?
			return code < 400
		end

		def dump_to_file
			# Generate a path
			tmpfile = ::Tempfile.new('response')
			path = tmpfile.path
			tmpfile.close!
			tmpfile.unlink

			File.open(path, 'w') do |f|
				f.write("#{inspect}\n#{to_s}")
			end

			return path
		end

		def validate!
			abort("Action failed, output at #{dump_to_file}") unless valid?
		end
	end
end

# HTTP has a chainable API, so keep a chain of all properties needed
chain = HTTP

# Login
puts 'Logging in'
res = chain.post(
	"#{STACK_URL}/login",
	form: {
		username: STACK_USERNAME,
		password: STACK_PASSWORD,
	},
)
res.validate!
chain = chain.cookies(res.cookies)

# Get the CSRF token
puts 'Gettings CSRF token'
res = chain.get("#{STACK_URL}/trashbin")
res.validate!
csrf_token = res.parse.andand.xpath('//meta[@name="csrf-token"]').first.andand.attr(:content)
abort("Cannot find CRSF token, output at #{res.dump_to_file}") unless csrf_token
chain = chain.headers('csrf-token' => csrf_token)

while true
	# Check remaining files
	puts 'Checking trashbin'
	res = chain.get(
		"#{STACK_URL}/api/files",
		params: {
			type: :trashbin,
			public: false,
			sortBy: :mtime,
			order: :desc,
			offset: 0,
			limit: 1,
			dir: '/',
			query: '',
			_: Time.now.to_i * 1000 + Time.now.usec / 1000,
		},
	)
	res.validate!
	res = res.parse
	remaining = res['amount']

	puts "Trashbin contains #{remaining} items"
	break if remaining <= 0

	# Clear the trash
	puts 'Clearing the trashbin'
	res = chain
		.headers('content-type' => 'application/json')
		.post(
			"#{STACK_URL}/api/trashbin",
			json: [{
				action: :delete,
				all: true,
				path: '/',
			}],
		)
	res.validate!
end

puts 'Done!'
