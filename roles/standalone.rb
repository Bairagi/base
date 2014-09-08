name 'standalone'
run_list ['role[master]', 'recipe[goatos::slave]']
