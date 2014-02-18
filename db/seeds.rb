# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Repeat.destroy_all

daily = IceCube::Rule.daily
Repeat.connection.execute %Q(insert into `repeats` values (6, 'Everyday', 1, now(), now(), '#{daily.psych_to_yaml}'))

mon_to_fri = IceCube::Rule.weekly.day :monday, :tuesday, :wednesday, :thursday, :friday
Repeat.connection.execute %Q(insert into `repeats` values (7, 'Monday to Friday', 2, now(), now(), '#{mon_to_fri.psych_to_yaml}'))

weekly = IceCube::Rule.weekly
Repeat.connection.execute %Q(insert into `repeats` values (8, 'Every Week', 3, now(), now(), '#{weekly.psych_to_yaml}'))

every_2_weeks = IceCube::Rule.weekly 2
Repeat.connection.execute %Q(insert into `repeats` values (9, 'Every 2 Weeks', 4, now(), now(), '#{every_2_weeks.psych_to_yaml}'))

monthly = IceCube::Rule.monthly
Repeat.connection.execute %Q(insert into `repeats` values (10, 'Every Month', 5, now(), now(), '#{monthly.psych_to_yaml}'))
