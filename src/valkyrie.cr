require "./valkyrie/**"
include Valkyrie

#raise "No file supplied" unless ARGV[1]

begin
	#prog=Parser.from_file(ARGV[1]).parse
	prog=Parser.new STDIN,"/home/inori/github/valkyrie"
	pp prog.parse
rescue e
	STDERR.puts e.message
	exit 1
end
