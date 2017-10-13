require "./valkyrie/**"
include Valkyrie

#raise "No file supplied" unless ARGV[1]

begin
	#prog=Parser.from_file(ARGV[1]).parse
	prog=Parser.new STDIN
	pp prog.parse
rescue e
	STDERR.puts "#{e.class.name.split("::")[-1]}: #{e.message}"
	exit 1
end
