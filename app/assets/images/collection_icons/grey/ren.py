import os

icons = ['bell.png', 'fire.png', 'bookmark.png', 'police.png', 'wifi.png', 'hand_truck.png', 'baby.png', 'pregnant.png', 'dog.png', 'building.png', 'bug.png', 'syringe.png', 'recycle.png', 'mountain.png', 'hospital.png', 'camera.png', 'anchor.png', 'pine.png', 'drop.png', 'faucet.png', 'box.png', 'printer.png', 'anthenna.png', 'tag.png', 'notebook.png', 'key.png', 'trashbin.png', 'car.png', 'helicopter.png', 'subway.png', 'bus.png', 'boat.png', 'airplane.png', 'factory.png', 'gas_pump.png', 'clark.png', 'mortarboard.png', 'truck.png', 'train.png', 'shopping_cart.png', 'barn.png', 'house.png', 'tunnel.png', 'tent.png', 'cog.png', 'flag.png', 'envelope.png', 'signpost.png', 'swing.png', 'test.png', 'medical_kit.png', 'family.png', 'wheat.png', 'group.png', 'robot.png', 'balance.png', 'biohazard.png']

offset = 457 
for i in range(0, len(icons)):
  os.rename('Pins_' + str(i + offset) + '.png', icons[i])

