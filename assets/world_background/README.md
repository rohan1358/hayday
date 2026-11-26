# Four Seasons reference terrain

Generated with the built-in imagegen tool from the user's Four Seasons reference.
The original reference remains outside the runtime bundle; this terrain image
contains no UI, buildings, fields, animals, signs or playable characters.

The image is drawn in world coordinates over 4320 × 7680 units. Separate game
assets use the same camera transform. Water, ponds, bridges and the distant
mountain strip have corresponding world collision checks in reference_terrain.gd.

Generation prompt:

Edit this exact map into a CLEAN TERRAIN-ONLY Godot background. Keep SAME
composition, SAME hills/cliffs, SAME meandering river and tributaries, SAME
four land plateaus, SAME winding paths and bridges, SAME mountains, forests
at far edges, spring green upper-left, summer yellow-green upper-right,
autumn orange lower-left, winter snow lower-right. REMOVE all UI, logo,
navigation, numbers, signs, labels, locks and all text. REMOVE all buildings,
crops, fences, animals, characters, furniture, fountain and interior standalone
trees. Fill their footprints with matching textured open ground. Keep original
banks, rocks, waterfalls, fishing pond, frozen pond, bridges and central EMPTY
plaza. No flat colored rectangles. No cross shaped straight river. Reconstruct
sky where UI was. Preserve exact river contours and terrain as close to the
reference as possible. This is a world background on which separate interactive
buildings and trees will be placed. Highly detailed same cheerful illustrated
game style. Output portrait image terrain only, edge to edge, no frame.
