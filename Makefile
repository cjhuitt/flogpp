default:
	echo "Dir.glob('./test/*_test.rb').each { |file| require file}" | ruby
