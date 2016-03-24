/proc/random_blood_type()
	return pick(4;"O-", 36;"O+", 3;"A-", 28;"A+", 1;"B-", 20;"B+", 1;"AB-", 5;"AB+")

/proc/random_eye_color()
	switch(pick(20;"brown",20;"hazel",20;"grey",15;"blue",15;"green",1;"amber",1;"albino"))
		if("brown")		return "630"
		if("hazel")		return "542"
		if("grey")		return pick("666","777","888","999","aaa","bbb","ccc")
		if("blue")		return "36c"
		if("green")		return "060"
		if("amber")		return "fc0"
		if("albino")	return pick("c","d","e","f") + pick("0","1","2","3","4","5","6","7","8","9") + pick("0","1","2","3","4","5","6","7","8","9")
		else			return "000"

/proc/random_underwear(gender)
	if(!underwear_list.len)
		init_sprite_accessory_subtypes(/datum/sprite_accessory/underwear, underwear_list, underwear_m, underwear_f)
	switch(gender)
		if(MALE)	return pick(underwear_m)
		if(FEMALE)	return pick(underwear_f)
		else		return pick(underwear_list)

/proc/random_undershirt(gender)
	if(!undershirt_list.len)
		init_sprite_accessory_subtypes(/datum/sprite_accessory/undershirt, undershirt_list, undershirt_m, undershirt_f)
	switch(gender)
		if(MALE)	return pick(undershirt_m)
		if(FEMALE)	return pick(undershirt_f)
		else		return pick(undershirt_list)

/proc/random_socks(gender)
	if(!socks_list.len)
		init_sprite_accessory_subtypes(/datum/sprite_accessory/socks, socks_list, socks_m, socks_f)
	switch(gender)
		if(MALE)	return pick(socks_m)
		if(FEMALE)	return pick(socks_f)
		else		return pick(socks_list)

/proc/random_hair_style(gender)
	switch(gender)
		if(MALE)	return pick(hair_styles_male_list)
		if(FEMALE)	return pick(hair_styles_female_list)
		else		return pick(hair_styles_list)

/proc/random_facial_hair_style(gender)
	switch(gender)
		if(MALE)	return pick(facial_hair_styles_male_list)
		if(FEMALE)	return pick(facial_hair_styles_female_list)
		else		return pick(facial_hair_styles_list)

/proc/random_name(gender, attempts_to_find_unique_name=10)
	for(var/i=1, i<=attempts_to_find_unique_name, i++)
		if(gender==FEMALE)	. = capitalize(pick(first_names_female)) + " " + capitalize(pick(last_names))
		else				. = capitalize(pick(first_names_male)) + " " + capitalize(pick(last_names))

		if(i != attempts_to_find_unique_name && !findname(.))
			break

/proc/random_skin_tone()
	return pick(skin_tones)

/proc/random_name_mutant(var/mut_id)	//this will generate names to each mutant race
	switch(mut_id)
		if("lizard")
			. = name_lizard()
			return
		if("plant")
			. = name_plant()
			return
		if("shadow")
			. = name_shadow()
			return
		if("jelly")
			. = name_jelly()
			return
		if("fly")
			. = name_fly()
			return
		if("skeleton")
			. = name_skeleton()
			return
		if("zombie")
			. = name_zombie()
			return
		if("abductor")
			. = name_abductor()
			return
	. = random_name()	//if all else fails, pick a normal random name. Shouldn't really happen
	return

var/list/skin_tones = list(
	"albino",
	"caucasian1",
	"caucasian2",
	"caucasian3",
	"latino",
	"mediterranean",
	"asian1",
	"asian2",
	"arab",
	"indian",
	"african1",
	"african2"
	)

var/global/list/species_list[0]
var/global/list/roundstart_species[0]

/proc/age2agedescription(age)
	switch(age)
		if(0 to 1)			return "infant"
		if(1 to 3)			return "toddler"
		if(3 to 13)			return "child"
		if(13 to 19)		return "teenager"
		if(19 to 30)		return "young adult"
		if(30 to 45)		return "adult"
		if(45 to 60)		return "middle-aged"
		if(60 to 70)		return "aging"
		if(70 to INFINITY)	return "elderly"
		else				return "unknown"

/*
Proc for attack log creation, because really why not
1 argument is the actor
2 argument is the target of action
3 is the description of action(like punched, throwed, or any other verb)
4 should it make adminlog note or not
5 is the tool with which the action was made(usually item)					5 and 6 are very similar(5 have "by " before it, that it) and are separated just to keep things in a bit more in order
6 is additional information, anything that needs to be added
*/

proc/add_logs(mob/user, mob/target, what_done, var/admin=1, var/object=null, var/addition=null)
	var/newhealthtxt = ""
	if (target && isliving(target))
		var/mob/living/L = target
		newhealthtxt = " (NEWHP: [L.health])"
	if(user && ismob(user))
		user.attack_log += text("\[[time_stamp()]\] <font color='red'>Has [what_done] [target ? "[target.name][(ismob(target) && target.ckey) ? "([target.ckey])" : ""]" : "NON-EXISTANT SUBJECT"][object ? " with [object]" : " "][addition][newhealthtxt]</font>")
	if(target && ismob(target))
		target.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been [what_done] by [user ? "[user.name][(ismob(user) && user.ckey) ? "([user.ckey])" : ""]" : "NON-EXISTANT SUBJECT"][object ? " with [object]" : " "][addition][newhealthtxt]</font>")
	if(admin)
		log_attack("[user ? "[user.name][(ismob(user) && user.ckey) ? "([user.ckey])" : ""]" : "NON-EXISTANT SUBJECT"] [what_done] [target ? "[target.name][(ismob(target) && target.ckey)? "([target.ckey])" : ""]" : "NON-EXISTANT SUBJECT"][object ? " with [object]" : " "][addition][newhealthtxt]")

//Mutant name generation for each race. If it gets too big, we might to start using config files like normal names do.

/proc/name_lizard()
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		//first word, should be a verb
		generated_name = pick("Runs",
								"Hisses",
								"Chases",
								"Hunts",
								"Wags",
								"Hugs",
								"Brews",
								"Scratches",
								"Slithers",
								"Plays,"
								"Awakes",
								"Burns",
								"Rolls",
								"lifts")
		generated_name += "-"
		//second word
		generated_name += pick("My",
								"His",
								"Her",
								"Our",
								"Your",
								"Their",
								"Every",
								"No",
								"Most",
								"With,")
		generated_name += "-"
		//third word, should be a noun, related to nature
		generated_name += pick("Trees",
								"Lake",
								"Bark",
								"Moon",
								"Sun",
								"Sand",
								"Branches",
								"Flies",
								"Prey",
								"Predator,"
								"Sap",
								"Tail",
								"Drink"
								"Water",
								"Earth",
								"Fire",
								"Air")
		. = generated_name
		if(i != attempts && !findname(.))
			break

/proc/name_plant()
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		generated_name = pick("A.",
								"B.",
								"C.",
								"D.",
								"E.",
								"F.",
								"G.",
								"H.",
								"I.",
								"J.",
								"K.",
								"L.",
								"M.",
								"N.",
								"O.",
								"P.",
								"Q.",
								"R.",
								"S.",
								"T.",
								"U.",
								"V.",
								"W.",
								"Q.",
								"Y.",
								"Z.")
		generated_name += " "
		//second word
		generated_name += pick("decidua",
								"viride",
								"carota",
								"nigra",
								"papyrifera",
								"pendula",
								"lenta",
								"allahuiensis",
								"farinosa",
								"trifida",
								"serotina",
								"sempervirens",
								"aquifolium",
								"monensis",
								"nanotrasinis",
								"syndicatia",
								"major",
								"tuberosa",
								"flavula",
								"scientia",
								"sylvestris",
								"bulbosa,"
								"kousa",
								"incontinentia",
								"caroliniana")
		. = generated_name
		if(i != attempts && !findname(.))
			break

/proc/name_shadow()
	//shadows get a randomly generated first name and a randomly picked last name
	//first name is how they're suposedly called, last name is a title
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		//generate first name, Should be two consonants, one vogal, one consonant, one vogal again and one consonant to finish
		//might end up with something unpronouncable, which is kinda okay
		generated_name = pick("S","K","T","R","D","G","Z","V","N")
		if(prob(75)) //25% of them won't have the extra consonant
			generated_name += pick("v","x","z","k","s","r","h","l","m")
		generated_name += pick("a","e","i","o","u")
		if(prob(50))	//to not have all names be the same length
			generated_name += pick("v","x","z","k","s","r","h","l","m")
			generated_name += pick("a","e","i","o","u")
		generated_name += pick("s","k","t","r","d","g","z","v","n")

		generated_name += " the "

		//second name is a title. Pretty edgy, but then again, this is the edgy race.
		generated_name += pick("Tormenter",
								"Demented",
								"Shadow",
								"Hedghog", //this will cause lynchings
								"Outsider",
								"Revenant",
								"Spectre",
								"Dark",
								"Edgy",		//Hue
								"Brooding,"
								"Guardian",
								"Watcher",
								"Bloodied"
								"Impaler",
								"Spiked",
								"Tortured",
								"Screamer",
								"Carpathian")
		. = generated_name
		if(i != attempts && !findname(.))
			break

/proc/name_jelly()
	//names should sound cute or down right retarded. First name separated from last name with an hiphen
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		generated_name = pick("Chu",
								"Suu",
								"Malu",
								"Nur",
								"Dyil",
								"Anni",
								"Tel",
								"Meer",
								"Reee",
								"Sehe")
		generated_name += "-"
		generated_name += pick("Alum",
								"Galei",
								"Hai",
								"Nof",
								"Durei",
								"Selo",
								"Fea",
								"Vien",
								"Tuli",
								"Cio",
								"Nery",
								"Mae",
								"Lin",
								"Hej",
								"Kelo",
								"Pari",
								"Potum")
		. = generated_name
		if(i != attempts && !findname(.))
			break

/proc/name_fly()
	//names with lots of ZZZZs, all of them start with Z too
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		//first name
		generated_name = "Z"
		if(prob(75)) generated_name += "Z"
		if(prob(50)) generated_name += "Z"
		if(prob(25)) generated_name += "Z"
		generated_name += pick("a","ai","e","ea","i","io","o","oa","u","ui")
		generated_name += pick("l","sh","th","k","nth","v","st")
		generated_name += " "
		//second name, always end in Z, with possibillity of two extra Zs
		generated_name += pick("Pl","R","F","K","Th","V","St")
		generated_name += pick("a","ai","e","ea","i","io","o","oa","u","ui")
		if(prob(75)) generated_name += "z"
		if(prob(50)) generated_name += "z"
		generated_name += "Z"
		. = generated_name
		if(i != attempts && !findname(.))
			break

/proc/name_skeleton()
	//pretty much just roman names, rolled with some puns
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		generated_name = pick("Julius",
								"Brutus",
								"Atticus",
								"Cassius",
								"Lucius",
								"Magnus",
								"Marcus",
								"Maximus",
								"Octavius",
								"Remus",
								"Rufus",
								"Agrippa",
								"Augustus",
								"Aurelius",
								"Caius",
								"Cornelius",
								"Decimus",
								"Domitius",
								"Festus",
								"Hilarius",
								"Horatius",
								"Nero,"
								"Pontius",
								"Regulus",
								"Septimus",
								"Incontinentia")
		generated_name += " "
		generated_name += pick("Ambustus",
								"Arquitius",
								"Africanus",
								"Bubulcus",
								"Caudinus",
								"Cincinnatus",
								"Drusus",
								"Gallaecus",
								"Globulus",
								"Helenus",
								"Hortator",
								"Juncus",
								"Lactucinus",
								"Licinianus",
								"Mamilianus",
								"Nasica",
								"Octavianus",
								"Paullus",
								"Pictor",
								"Regillensis",
								"Salinator",
								"Sapiens,"
								"Sibylla",
								"Structus",
								"Torquatus",
								"Buttox")
		. = generated_name
		if(i != attempts && !findname(.))
			break

/proc/name_zombie()
	//picks a consonant, and optional consonant a vowel and then a few repeat consonants
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		generated_name = pick("B",
								"C",
								"D",
								"F",
								"G",
								"H",
								"J",
								"K",
								"L",
								"M",
								"N",
								"P",
								"S",
								"T",
								"V",
								"Z")
		if(prob(40))
			generated_name += pick("r","s","l")
		var/vowel = pick("a","e","i","o","u")
			generated_name += vowel + vowel + vowel
		if(prob(75)
			generated_name += vowel + vowel
		if(prob(50)
			generated_name += vowel + vowel
		if(prob(25)
			generated_name += vowel
		generated_name += pick("r","t","p","s","d","f","g","h","k","l","c","b","n")
		generated_name += " the "
		//funny words that are synonim with Zombie or related to corpses. Don't actually use Zombie here.
		generated_name += pick("Corpse",
								"Shambler",
								"Walker",
								"Rotting",
								"Body",
								"Dead",
								"Muncher",
								"Bloated",
								"Oogler",
								"Hunchback",
								"Shuffler",
								"Thriller",
								"Living",
								"Deceased",
								"Gone",
								"Patient",
								"Undead")


		. = generated_name
			if(i != attempts && !findname(.))
				break
/proc/name_abductor()
	//Should sound alien and weird. Three Sylabe composed name with no surname
	//Will need further expansion later, albeit 3 sylabes is enough for a bunch of variations
	var/generated_name
	var/attempts = 10
	for(var/i=1, i<=attempts, i++)
		generated_name = pick("Daa",
								"Kaa",
								"Maa",
								"Raa",
								"Saa",
								"Dee",
								"Kee",
								"Mee",
								"Ree",
								"See")
		generated_name += pick("'lo",
								"'mo",
								"'no",
								"'bo",
								"'do",
								"'fo",
								"'go",
								"'ro",
								"'vo",
								"'zo")
		generated_name += pick("dok",
								"las",
								"gan",
								"nok",
								"vel")
		. = generated_name
		if(i != attempts && !findname(.))
			break