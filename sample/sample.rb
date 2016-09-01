# Bad: write Pathname("path.rb") instead
path = Pathname.new("path.rb")

# Bad: Pass block to File.open to make sure the file will be closed
io = File.open("hoge.txt", "+w")
