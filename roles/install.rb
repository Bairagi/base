name 'install'
run_list ['recipe[goatos::install]', 'recipe[goatos::configure]']
