# Uninstall hook code here

main_app_path = File.join(RAILS_ROOT, 'public', 'asktheeu-theme')
if File.exists?(main_app_path) && File.symlink?(main_app_path)
	print "Deleting symbolink link at #{main_app_path}... "
	puts `rm #{main_app_path}`
	puts "done"
end