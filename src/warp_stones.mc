
function load {
	scoreboard objectives add wc.i dummy
	execute if data storage wc:ram {enable:{warp_stones:1b}} run function warp_stones:clock_1s
	execute unless data storage wc:ram {enable:{warp_stones:1b}} run schedule clear warp_stones:clock_1s
}

function disable {
	data modify storage wc:ram enable.warp_stones set value 0b
}
function enable {
	data modify storage wc:ram enable.warp_stones set value 1b
}

function clock_1s {
	# Tag eyes of ender with we.ender_eye
	execute as @e[type=item,tag=!wc.checked] run {
		tag @s[nbt={Item:{id:"minecraft:ender_eye",Count:1b}}] add wc.ender_eye
		tag @s add wc.checked
	}
	# Execute as and at eyes of ender on the ground to check if there are on top of a warp stone construct. If there is one, create a warp stone entity
	execute as @e[type=item,tag=wc.ender_eye,nbt={OnGround:1b}] at @s unless entity @e[type=glow_item_frame,tag=wc.warp_stone,distance=..2,limit=1] positioned ~ ~-1 ~ if block ~1 ~ ~ #minecraft:stairs if block ~-1 ~ ~ #minecraft:stairs if block ~ ~ ~1 #minecraft:stairs if block ~ ~ ~-1 #minecraft:stairs if block ~1 ~ ~1 #minecraft:slabs if block ~-1 ~ ~1 #minecraft:slabs if block ~1 ~ ~-1 #minecraft:slabs if block ~-1 ~ ~-1 #minecraft:slabs if block ~ ~ ~ minecraft:iron_block align xyz positioned ~.5 ~ ~.5 run {
		playsound minecraft:block.respawn_anchor.charge block @a ~ ~ ~ 1 0.1
		playsound minecraft:item.lodestone_compass.lock block @a ~ ~ ~ 1 0.1
		playsound minecraft:block.beacon.power_select block @a ~ ~ ~ 1 0.1
		LOOP(64,i){
			particle minecraft:end_rod ~<%Math.sin(i*360)*0.5%> ~1.25 ~<%Math.cos(i*360)*0.5%> <%Math.sin(i*360)*0.5%> -0.25 <%Math.cos(i*360)*0.5%> 0.5 0 force
		}
		summon glow_item_frame ~ ~1 ~ {Tags:["wc.warp_stone","wc.new"],Item:{id:"minecraft:ender_eye",Count:1b},Fixed:1b,Facing:1b,Invisible:1b,Invulnerable:1b,Silent:1b}
		kill @s
	}
	# Count how many warp stones exist
	execute store result score #count wc.i if entity @e[type=glow_item_frame,tag=wc.warp_stone]
	# Execute logic as all warp pad entities
	execute as @e[type=glow_item_frame,tag=wc.warp_stone] at @s run {
		# If there is more than one warp pad in existance
		execute if score #count wc.i matches 2.. run {
			# Fancy particles
			LOOP(32,i){
				particle minecraft:end_rod ~<%Math.sin(i*360)*1.4%> ~-0.5 ~<%Math.cos(i*360)*1.4%> <%Math.sin(i*360)*-0.2%> 0.3 <%Math.cos(i*360)*-0.2%> 0.25 0 force
			}
			# Warp the nearest player standing on top of the warp stone
			execute if entity @p[distance=..0.5] run {
				tag @p[distance=..0.5] add wc.warping
				execute as @e[type=glow_item_frame,tag=wc.warp_stone,distance=2..,limit=1,sort=random] positioned as @s run {
					tp @a[tag=wc.warping] ~ ~.1 ~
					tag @a remove wc.warping
					kill @s
					# More fancy particles
					LOOP(360,i){
						particle minecraft:end_rod ~<%Math.sin(i*360)*0.75%> ~<%Math.tan(i)%> ~<%Math.cos(i*360)*0.75%> <%Math.sin(i*360)*0.25%> 0 <%Math.cos(i*360)*0.25%> 1 0 force
					}
					stopsound @a[distance=..10] block minecraft:ambient.soul_sand_valley.mood
					playsound minecraft:item.trident.thunder block @a ~ ~ ~ 1 2
				}
				# Even more fancy particles
				LOOP(5,y){
					LOOP(32,i){
						particle minecraft:end_rod ~<%Math.sin(i*360)*0.75%> ~ ~<%Math.cos(i*360)*0.75%> 0 <%(y+1)*0.25%> 0 1 0 force
					}
				}
				playsound minecraft:item.trident.riptide_1 block @a ~ ~ ~ 1 2
				stopsound @a[distance=..10] block minecraft:ambient.soul_sand_valley.mood
				kill @s
			}
		}
		# Man I do love me some fancy particles
		LOOP(32,i){
			particle minecraft:portal ~<%Math.sin(i*360)*0.75%> ~.5 ~<%Math.cos(i*360)*0.75%> 0 -1 0 1 0 force
		}
		# Ambient sound effect
		playsound minecraft:ambient.soul_sand_valley.mood block @a ~ ~ ~ 0.5 0.1
		# If the warp stone construct is broken/missing blocks then play the breaking animation
		tag @s add break
		execute positioned ~ ~-1 ~ if block ~1 ~ ~ #minecraft:stairs if block ~-1 ~ ~ #minecraft:stairs if block ~ ~ ~1 #minecraft:stairs if block ~ ~ ~-1 #minecraft:stairs if block ~1 ~ ~1 #minecraft:slabs if block ~-1 ~ ~1 #minecraft:slabs if block ~1 ~ ~-1 #minecraft:slabs if block ~-1 ~ ~-1 #minecraft:slabs if block ~ ~ ~ minecraft:iron_block run tag @s remove break
		execute if entity @s[tag=break] run {
			playsound minecraft:item.bottle.empty block @a ~ ~ ~ 1 2
			playsound minecraft:block.sculk_sensor.clicking block @a ~ ~ ~ 1 2
			stopsound @a[distance=..10] block minecraft:ambient.soul_sand_valley.mood
			# All the fancy particles!
			LOOP(64,i){
				particle minecraft:item ender_eye ~ ~ ~ <%Math.sin(i*360)%> 1 <%Math.cos(i*360)%> 0.25 0 force
			}
			kill @s
		}
	}
	# Tick this function
	schedule function warp_stones:clock_1s 1s
}
