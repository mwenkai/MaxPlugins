global NowSchedule = 1

rollout Documentation "注意"
(
	label lab1 "材质导出须知："
	label lab2 "1、Unreal中仅识别标准材质/多维子材质"
	label lab3 "2、Unreal无法导入Tif格式的图片，需事先转换"
	button closebutton "关闭说明"
	
	on closebutton pressed do
	(
		removerollout Documentation
	)
)

rollout AlphoeniXTool "一键自动命名"
(
	edittext MeshNamePrefixion "网格物体前缀名" text:"SM_" readonly:true width:120 pos:[10,0]
	edittext MeshNameMiddle "网格物体中间名" width:120 pos:[140,0]
	button MeshNameChanger "一键模型改名" height:30
	button InstanceMaterial "材质独立化" width:85 height:50 pos:[100,60]
	groupbox group1 "一键更换材质名" pos:[0,120] width:140 height:100
	groupbox group2 "一键更换贴图名" pos:[145,120] width:140 height:100
	button NameChanger "自动更改材质名称" pos:[10,180] height:30
	button TextureChanger "自动修改贴图名称" pos:[155,180] height:30
	edittext MaterialPrefixion "材质前缀名" text:"MI_" readonly:true width:100 pos:[10,150]
	edittext TexturePrefixion "贴图前缀名" text:"T_" readonly:true width:100 pos:[155,150]
	global SelectFileName = ""
	global SelectBump = ""
	global IsNormalBump = false
	global addr = ""
	global FileType = ""
	
---------------------------函数块分割线---------------------------
	
	fn MakeNewMaterial m =
	(
		m.material = copy m.material
	)
	
	fn MakeNewMaterialMulti m = 
	(
		local jishu = 44
		print m.material.count
--		while jishu<=m.material.jishu do
--		(
--			m.material[jishu]=copy m.material[jishu]
--			jishu+=1
--		)
	)

---------------------------实现块分割线---------------------------

	on MeshNameChanger pressed do
	(
		try (destroydialog schedulebar) catch ()
		for objs in selection do
		(
			if (substring objs.name 1 3) != "SM_" then
			(
				objs.name = MeshNamePrefixion.text + MeshNameMiddle.text + objs.name
				NowSchedule+=1
			)
		)
	)
	
	on InstanceMaterial pressed do
	(
		global count=1
		for objs in selection do
		(
			/*if (matchPattern (objs.material as string) pattern:"#Multi/Sub-Object*")
			then
			(
--				messagebox "多维材质复制"
				while count<=objs.material.count do
				(
					objs.material[count]=copy objs.material[count]
					count+=1
				)
			)
			else
			(
				objs.material=copy objs.material
			)*/
			objs.material=copy objs.material
		)
	)
	
	on NameChanger pressed do
	(
		successcount=0
		failcount=0
		print selection
		for objs in selection do
		(
			count=1 --重置计数器
			if (matchPattern (objs.name as string) pattern:"SM_*") and (objs.material != undefined) --判断名称是否匹配格式
			then
			(
				objs.material.name=(substring objs.name 2 -1)
				if (matchPattern (objs.material as string) pattern:"#Multi/Sub-Object*") --判断是否为多维子材质
				then
					(
					print"in"
					while count<=objs.material.count do
						(
							try
							(
								objs.material[count].name=objs.material.name + "_00" + (count as string)
							)
							catch()
							count+=1
						) 
					)
				successcount+=1
			)
			else
			(
				messagebox (objs.name+"的命名没有以\"SM_\"开头或模型没有定义材质")
				failcount+=1
			)
		)
		messagebox ("修改完成，共成功"+(successcount as string)+"个模型，失败"+(failcount as string)+"个模型")
		successcount=0 --重置成功计数器
		failcount=0 --重置失败计数器
	)
	
	on TextureChanger pressed do
	(
		count=1 
		for objs in selection do
		(
			if (matchPattern (objs.material as string) pattern:"#Multi/Sub-Object*")
			then --多维子材质的处理方法
			(
--				messagebox "进入多维子材质处理流程"
				count=1
				while count<=objs.material.count do
				(
					try 
					(
						objs.material[count].diffusemap.filename --判断是否存在漫反射贴图
						SelectFileName = substring objs.material[count].diffusemap.filename ((getfilenamepath objs.material[count].diffusemap.filename).count+1) -1 --获得漫反射贴图文件名
						if ((substring SelectFileName 1 2) == "T_") then --判断漫反射的贴图文件名是否已经符合格式
						(
--							messagebox "这个材质已经有了正确的贴图名称格式"
							objs.material[count].DiffuseMap.coords.u_tiling = 1
							objs.material[count].DiffuseMap.coords.v_tiling = 1
						)
						else
						(
							addr = objs.material[count].diffusemap.filename
							FileType = getfilenametype addr
							copyfile addr ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_D" + (count as string) + FileType)
							objs.material[count].diffusemap.filename = ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_D" + (count as string) + FileType)
							objs.material[count].DiffuseMap.coords.u_tiling = 1
							objs.material[count].DiffuseMap.coords.v_tiling = 1
						)
					)
					catch()
					IsNormalBump = false
					try --判断是会否含有法线凹凸
					(
						objs.material[count].bumpmap.normal_map.filename
						IsNormalBump = true
					) 
					catch
					(
--						messagebox (objs.name + "Is Not Normal Bump")
						IsNormalBump = false
					)
					if IsNormalBump == true then
					(
						addr = objs.material[count].bumpmap.normal_map.filename
						SelectFileName = substring addr ((getfilenamepath addr).count+1) -1
						FileType = getfilenametype addr
						if (substring SelectFileName 1 2) == "T_" then
						(
--							messagebox "这个材质已经有了正确的法线贴图名称"
							objs.material[count].bumpmap.normal_map.coords.u_tiling = 1
							objs.material[count].bumpmap.normal_map.coords.v_tiling = 1
						)
						else
						(
							copyfile addr ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + (count as string) + FileType)
							objs.material[count].bumpmap.normal_map.filename = ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + (count as string) + FileType)
							objs.material[count].bumpmap.normal_map.coords.u_tiling = 1
							objs.material[count].bumpmap.normal_map.coords.v_tiling = 1
						)
					)
					else
					(
						try
						(
							addr = objs.material[count].bumpmap.filename
							if (addr != undefined) and ((substring (filenamefrompath addr) 1 2) !="T_") then
							(
								FileType = getfilenametype addr
								copyfile addr ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + (count as string) + FileType)
								objs.material[count].bumpmap.filename = ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + (count as string) + FileType)
								objs.material[count].bumpmap.coords.u_tiling=1
								objs.material[count].bumpmap.coords.v_tiling=1
--								messagebox "修改完成"
							)
							else
							(
--								messagebox (objs.name + "已经具有了正确命名格式的法线贴图")
								objs.material[count].bumpmap.coords.u_tiling=1
								objs.material[count].bumpmap.coords.v_tiling=1
							)
						)
						catch
						(
--							messagebox (objs.name + "没有凹凸贴图或为法线凹凸贴图")
						)
					)
					count+=1
				)
			)
			else --标准材质的处理方法
			(
				try --判断是否存在漫反射贴图
				(
					objs.material.diffusemap.filename
					SelectFileName = substring objs.material.diffusemap.filename ((getfilenamepath objs.material.diffusemap.filename).count+1) -1 --获得漫反射贴图文件名
					if ((substring SelectFileName 1 2) == "T_") then --判断漫反射的贴图文件名是否已经符合格式
					(
--						messagebox "这个材质已经有了正确的贴图名称格式"
					)
					else
					(
						addr = objs.material.diffusemap.filename
						FileType = getfilenametype addr
						copyfile addr ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_D" + FileType)
						objs.material.diffusemap.filename = ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_D" + FileType)
						objs.material.diffusemap.coords.u_tiling = 1
						objs.material.diffusemap.coords.v_tiling = 1
					)
				)
				catch()
				IsNormalBump = false
				try --判断是会否含有法线凹凸
				(
					objs.material.bumpmap.normal_map.filename
					IsNormalBump = true
				) 
				catch
				(
--					messagebox (objs.name + "Is Not Normal Bump")
					IsNormalBump = false
				)
				if IsNormalBump == true then
				(
					addr = objs.material.bumpmap.normal_map.filename
					SelectFileName = substring addr ((getfilenamepath addr).count+1) -1
					FileType = getfilenametype addr
					if (substring SelectFileName 1 2) == "T_" then
					(
--						messagebox "这个材质已经有了正确的法线贴图名称"
						objs.material.bumpmap.normal_map.coords.v_tiling = 1
						objs.material.bumpmap.normal_map.coords.u_tiling = 1
					)
					else
					(
						copyfile addr ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + FileType)
						objs.material.bumpmap.normal_map.filename = ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + FileType)
						objs.material.bumpmap.normal_map.coords.u_tiling = 1
						objs.material.bumpmap.normal_map.coords.v_tiling = 1
					)
				)
				else
				(
					try
					(
						addr = objs.material.bumpmap.filename
						if (addr != undefined) and ((substring (filenamefrompath addr) 1 2) !="T_") then
						(
							FileType = getfilenametype addr
							copyfile addr ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + FileType)
							objs.material.bumpmap.filename = ((getfilenamepath addr) + "T_" + (substring objs.name 4 -1) + "_N" + FileType)
							objs.material.bumpmap.coords.v_tiling = 1
							objs.material.bumpmap.coords.u_tiling = 1
--							messagebox "修改完成"
						)
						else
						(
--							messagebox (objs.name + "已经具有了正确命名格式的法线贴图")
							objs.material.bumpmap.coords.v_tiling = 1
							objs.material.bumpmap.coords.u_tiling = 1
						)
					)
					catch
					(
--						messagebox (objs.name + "没有凹凸贴图或为法线凹凸贴图")
					)
				)
			)
		)
		messagebox "自动更改贴图名完成"
	)
)

---------------------------一键材质转换---------------------------

global discrimina
global seltipo
global origtipo
global crisnegros
global forzar
global animcam
global borracam
global mensajes
global ventana
global mapas
global camaras= #()
global newcam= #()
global luces = #()
global newluz = #()
global dir
global dirproc
global mapdir
global procedural
global anchoproc
global altoproc
global extension
global mapaout
global flota
global motores_destino = #()
global roll_acciones,roll_Thea --para evitar que se queje
global nombre_vray
global borraluz
global animluz
fn sqr x = x*x
global unit_factor
global theObj 
global templog
global kk

-----------------------------------------------
--- TABLAS---
-----------------------------------------------
temp_array_RGB=#((color 255 35.33 0.1),(color 255 41.25 0.44),(color 255 47.26 0.981926),(color 255 53.32 1.77),(color 255 59.41 2.84),(color 255 65.51 4.23),
							(color 255 71.60 5.95),(color 255 77.68 8.01),(color 255 83.72 10.44),(color 255 89.73 13.23),(color 255 95.7 16.37),(color 255 101.61 19.87),
							(color 255 107.48 23.71),(color 255 113.3 27.89),(color 255 119.05 32.38),(color 255 124.75 37.17),(color 255 130.4 42.25),(color 255 135.98 47.6),
							(color 255 141.5 53.20),(color 255 146.96 59.05),(color 255 152.35 65.12),(color 255 157.69 71.4),(color 255 162.9 77.87),(color 255 168.16 84.51),
							(color 255 173.31 91.32),(color 255 178.39 98.27),(color 255 183.41 105.36),(color 255 188.37 112.58),(color 255 193.26 119.9),(color 255 198.1 127.32),
							(color 255 202.85 134.8),(color 255 207.56 142.4),(color 255 212.21 150.1),(color 255 216.8 157.8),(color 255 221.3 165.55),(color 255 225.78 173.35),
							(color 255 230.18 181.19),(color 255 234.52 189.05),(color 255 238.8 196.93),(color 255 243.02 204.81),(color 255 247.19 212.71),(color 255 251.3 220.6),
							(color 254.66 255 228.18),(color 250.74 255 232.4),(color 247 255 236.55),(color 243.4 255 240.6),(color 239.96 255 244.55),(color 236.67 255 248.42),
							(color 233.51 255 252.2),(color 229.66 254.1 255),(color 223.6 250.56 255),(color 217.88 247.19 255),(color 212.48 243.98 255),(color 207.36 240.92 255),
							(color 202.52 238 255),(color 197.93 235.22 255),(color 193.57 232.55 255),(color 189.44 230 255),(color 185.5 227.56 255),(color 181.76 225.23 255),
							(color 178.19 223 255),(color 174.78 220.84 255),(color 171.53 218.8 255),(color 168.43 216.76 255),(color 165.46 214.88 255),(color 162.65 213.04 255),
							(color 159.91 211.28 255),(color 157.3 209.57 255),(color 154.81 207.93 255),(color 152.41 206.35 255),(color 150.11 204.83 255),(color 147.9 203.35 255),
							(color 145.77 201.93 255),(color 143.73 200.55 255),(color 141.76 199.22 255),(color 139.87 197.94 255),(color 138.04 196.7 255),(color 136.28 195.49 255),
							(color 134.58 194.3 255),(color 132.94 193.19 255),(color 131.35 192.1 255),(color 129.83 191.03 255),(color 128.35 190 255),(color 126.92 189 255),
							(color 125.53 188.03 255),(color 124.19 187.09 255),(color 122.9 186.17 255),(color 121.64 185.28 255),(color 120.42 184.4 255),(color 119.24 183.57 255),
							(color 118.1 182.75 255),(color 116.99 181.95 255),(color 115.91 181.17 255),(color 114.86 180.42 255),(color 113.85 179.68 255),(color 112.86 178.96 255),
							(color 111.9 178.27 255),(color 110.96 177.58 255),(color 110.05 176.92 255),(color 109.17 176.27 255),(color 108.31 175.64 255),(color 107.47 175.02 255),
							(color 106.66 174.42 255),(color 105.86 173.83 255),(color 105.1 173.25 255),(color 104.33 172.69 255),(color 103.6 172.14 255),(color 102.88 171.6 255),
							(color 102.18 171.09 255),(color 101.5 170.57 255),(color 100.83 170.07 255),(color 100.18 169.58 255),(color 99.55 169.1 255),(color 98.93 168.63 255),
							(color 98.32 168.17 255),(color 97.73 167.72 255),(color 97.13 167.28 255),(color 96.58 166.85 255),(color 96.03 166.42 255),(color 95.49 166 255),
							(color 94.96 165.6 255),(color 94.44 165.21 255),(color 93.93 164.82 255),(color 93.44 164.43 255),(color 92.95 164.06 255),(color 92.45 163.69 255),
							(color 92 163.33 255),(color 91.55 162.98 255),(color 91.16 162.63 255),(color 90.67 162.29 255),(color 90.24 161.96 255),(color 89.82 161.63 255),
							(color 89.40 161.31 255),(color 89 161 255),(color 88.6 160.68 255),(color 88.21 160.38 255),(color 87.83 160.08 255),(color 87.46 159.78 255),
							(color 87.09 159.5 255),(color 86.73 159.21 255),(color 86.37 158.93 255))

fn fn_kelvin2rgb k =(
	if k<1000 or k>15000 then result=(color 255 255 255)
	else
	(
		resto = mod k 100
		if resto>49 then k=(k-resto+100) else k-=resto
		IDX=(k-900)/100
		result=temp_array_RGB[IDX]
	)
	result
)

fn fn_motores=
	(
		local motores = #()
		local num = rendererclass.classes.count
		for i = 1 to num do
		(
			append motores rendererclass.classes[i] as string
		)
		append motores_destino "---Select engine---"
		--if (finditem motores MaxwellRenderer  > 0) then append motores_destino "Maxwell Render"  --no hay manera de asignar maxwell como motor
		--if (finditem motores RandomControl_FRYRENDER > 0) then append motores_destino "FryRender"
		if (finditem motores mental_ray_renderer> 0) then append motores_destino "Mental Ray"
		if (finditem motores Default_Scanline_Renderer > 0) then append motores_destino "Scanline"
		if (finditem motores Thea_Render > 0) then append motores_destino "Thea Render"
		for i = 1 to num do
		(
			if ((matchPattern (motores[i] as string) pattern:"Vray*") or (matchPattern (motores[i] as string) pattern:"V_Ray*")) then
			(
				if ((matchPattern (motores[i] as string) pattern:"V_Ray_RT*")==false)
				then
				(
					nombre_vray = motores[i] --lo guardamos para luego
					append motores_destino "Vray" --a ver si dejan de cambiarle el nombre a la clase de vray pa no liar este pollo
				)
			) 
		)
		if (finditem motores Final_Render > 0) then append motores_destino "Final Render"
		append motores_destino "Colimo Aux. Shader"
		
	)
fn color_gamma col oldgam newgam=(
	nr = int(255.0 * ((col.r / 255.0) ^ (newgam / oldgam)))
	ng = int(255.0 * ((col.g / 255.0) ^ (newgam / oldgam)))
	nb = int(255.0 * ((col.b / 255.0) ^ (newgam / oldgam)))
	rescol=(color nr ng nb)
	rescol
)
	
fn fn_glossy glOrig = (
	if glOrig == 1.0 then gl = 0 else
	(
		gl = (289.743*glOrig^4-102.436*glOrig^3-13.359*glOrig^2+32.0705*glOrig)
	)
	return gl
)

fn fn_glossy_thea vrgl = (
	gl = (100-100*(189.119*vrgl^7-935.487*vrgl^6+1917.51*vrgl^5-2092.88*vrgl^4+1299.5*vrgl^3-453.399*vrgl^2+82.5067*vrgl-5.86894))
	return (gl as integer)
)

fn fn_capasmaxwell mat = (
	local i=0
	a=true
	while (a==true) do
	(
		a = maxwellMaterialSetActiveLayer material:mat layerindex:i
		i+=1		
	)
	return (i-1)
)

fn fn_capasmaxwell_old mat = (
	
-- 		a = maxwellMaterialSetActiveLayer material:mat layerindex:1
-- 		b = a as string
-- 		
-- 	if (matchpattern b pattern:"Maxwell*" == true)
-- 			
-- 		then 
-- 			(
-- 				capas = 1
-- 				return capas
-- 			)
-- 		else 
-- 			(
-- 				capas = 2
-- 				return capas
-- 			)
	capas = 1
	return capas
	)
	
fn rendercrop MapaOrig = (
	kk=mapaorig
	nom=mapPaths.getFullFilePath MapaOrig.filename
	nomproc = getFilenameFile nom
	ext=getFilenameType nom
	btemp=openbitmap MapaOrig.filename
	hsize=btemp.height
	wsize=btemp.width
	rbm = renderMap MapaOrig size:[wsize*MapaOrig.clipw,hsize*MapaOrig.cliph]
	rbm.filename = dirproc + "\\" + nomproc + "_crop" + ext
	format "Generate cropped map % ...\n" rbm.filename to:templog
	save rbm gamma:2.2
	nuevoproc = Bitmaptexture ()
	nuevoproc.filename = rbm.filename
	nuevoproc.name = nomproc
	close rbm
	return nuevoproc
)	
	
-----------------------------------------------------------
--  FUNCIONES PARA CONVERTIR A STANDARD  --
-----------------------------------------------------------
fn vray2std origMtl = (
	s=Standard()
	s.name=origMtl.name
	
	s.diffuse=origMtl.diffuse
	s.diffuseMap=origMtl.texmap_diffuse
	s.diffuseMapEnable=origMtl.texmap_diffuse_on
	s.diffuseMapAmount=origMtl.texmap_diffuse_multiplier
	s.bumpMap = origMtl.texmap_bump
	s.bumpMapAmount = origMtl.texmap_bump_multiplier
	s.bumpMapEnable = origMtl.texmap_bump_on
	
	format "Converted to %\n" s to:templog	
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+s.name+":Standardmaterial")) catch()
	return s
)

fn MW2std origmtl = (
	
	numcapas = fn_capasmaxwell_old origmtl
	
	if numcapas == 2 then --se toman s髄o 2 como m醲imo
	(
		m = Blend()
		m.name = origMtl.name
		a = m.map1
		b = m.map2
		--primera capa
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:0
		peso_A = origMtl.Layer_Weight
		if origMtl.Use_Emitter == on then 
		(
			a.useSelfIllumColor = on
			a.selfIllumColor = origMtl.Emitter_RGB_Color --de momento solo vale RGB
		) else
		(
			a.shaderType = 3
			a.name = origMtl.Layer_name
			a.Diffuse = origMtl.BSDF_Reflected_Color
			a.diffuseMap = origMtl.BSDF_Reflected_Color_Texture
			a.bumpMapAmount = origMtl.BSDF_Bump_Strength
			a.bumpMap = origMtl.BSDF_Bump_Strength_Texture
			a.Specular = origMtl.Fresnel_Color
			a.specularMap = origMtl.BSDF_Fresnel_Color_Texture
			if (origMtl.Transparency_Color.value > 0) then a.refractionMap = Raytrace ()
			a.opacityMap = origMtl.BSDF_Transparency_Color_Texture
			a.ior = origMtl.BSDF_Nd
			if origMtl.BSDF_Roughness < 5 then
			(
				a.reflectionMap = Raytrace ()
				a.specularLevel = 100
				a.glossiness = 95
			)  
			else
				(
					if (origMtl.BSDF_Roughness < 20) then 
						(
							a.reflectionMap = Raytrace ()
							a.specularLevel = 100
							a.glossiness = 80
						) 
						else 
							(
								a.diffuseRoughness = origMtl.BSDF_Roughness
							)
			)
			a.anisotropy = origMtl.BSDF_Anisotropy
			a.orientation = origMtl.BSDF_Anisotropy_Angle
		)
		
	
		--segunda capa
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:1
			peso_B = origMtl.Layer_Weight
			if origMtl.Use_Emitter == on then 
			(
				b.useSelfIllumColor = on
				b.selfIllumColor = origMtl.Emitter_RGB_Color --de momento solo vale RGB
			) else
			(
				b.shaderType = 3
				
				b.name = origMtl.Layer_name
				b.Diffuse = origMtl.BSDF_Reflected_Color
				b.diffuseMap = origMtl.BSDF_Reflected_Color_Texture
				b.bumpMapAmount = origMtl.BSDF_Bump_Strength
				b.bumpMap = origMtl.BSDF_Bump_Strength_Texture
				b.Specular = origMtl.Fresnel_Color
				b.specularMap = origMtl.BSDF_Fresnel_Color_Texture
				if (origMtl.Transparency_Color.value > 0) then b.refractionMap = Raytrace ()
				b.opacityMap = origMtl.BSDF_Transparency_Color_Texture
				b.ior = origMtl.BSDF_Nd
				if origMtl.BSDF_Roughness < 5 then
				(
					b.reflectionMap = Raytrace ()
					b.specularLevel = 100
					b.glossiness = 95
				)  
				else
				(
						if (origMtl.BSDF_Roughness < 20) then 
							(
								b.reflectionMap = Raytrace ()
								b.specularLevel = 100
								b.glossiness = 80
							) else b.diffuseRoughness = origMtl.BSDF_Roughness
				)
				
				b.anisotropy = origMtl.BSDF_Anisotropy
				b.orientation = origMtl.BSDF_Anisotropy_Angle
			)
			pesos = peso_A+peso_B
			m.mixAmount = 100-(peso_A*100/pesos)
			format "Converted to %\n" m to:templog
			try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Maxwell converted to "+s.name+":Standardmaterial")) catch()
			return m
	)
	else
	(
		--vamos s髄o con una capa
		m = Standard()
		m.name = origMtl.name
		--maxwellMaterialSetActiveLayer material:origMtl layerIndex:0  --no vale con plugin nuevo ARREGLAR
		if origMtl.Use_Emitter == on then 
		(
			m.useSelfIllumColor = on
			m.selfIllumColor = origMtl.Emitter_RGB_Color --de momento solo vale RGB
		) else
		(
			m.shaderType = 3
			m.name = origMtl.Layer_name
			m.Diffuse = origMtl.BSDF_Reflected_Color
			m.diffuseMap = origMtl.BSDF_Reflected_Color_Texture
			m.bumpMapAmount = origMtl.BSDF_Bump_Strength
			m.bumpMap = origMtl.BSDF_Bump_Strength_Texture
			m.Specular = origMtl.Fresnel_Color
			m.specularMap = origMtl.BSDF_Fresnel_Color_Texture
			if (origMtl.Transparency_Color.value > 0) then m.refractionMap = Raytrace ()
			m.opacityMap = origMtl.BSDF_Transparency_Color_Texture
			m.ior = origMtl.BSDF_Nd
			if origMtl.BSDF_Roughness < 5 then
			(
				m.reflectionMap = Raytrace ()
				m.specularLevel = 100
				m.glossiness = 95
			)  else
				(
					if (origMtl.BSDF_Roughness < 20) then 
						(
							m.reflectionMap = Raytrace ()
							m.specularLevel = 100
							m.glossiness = 80
						) else (m.diffuseRoughness = origMtl.BSDF_Roughness)
				) 
			m.anisotropy = origMtl.BSDF_Anisotropy
			m.orientation = origMtl.BSDF_Anisotropy_Angle
			
		)
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Maxwell converted to "+s.name+":Standardmaterial")) catch()
		return m
	)
)

fn Thea2std origmtl =(
	s=Standard()
	s.name=origMtl.name
	
	s.diffuse=origMtl.materiallist[1].diffuse
	if (origmtl.materiallist[1].diffuse_tex != undefined) then s.diffuseMap = ValidaMapaStd origmtl.materiallist[1].diffuse_tex
	
	
	format "Converted to %\n" s to:templog	
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":TheaMtl converted to "+s.name+":Standardmaterial")) catch()
	return s
)
-----------------------------------------------------------
--  FUNCIONES PARA CONVERTIR A VRAY  --
-----------------------------------------------------------
fn Std2vray origMtl = (
	v=VRayMtl()
	v.name=origMtl.name
	v.refraction_affectShadows = on
	v.diffuse=origMtl.diffuse
	v.texmap_diffuse=origMtl.diffuseMap
	v.texmap_diffuse_on=origMtl.diffuseMapEnable
	v.texmap_diffuse_multiplier=origMtl.diffuseMapAmount
	v.texmap_bump = origMtl.bumpMap
	v.texmap_bump_multiplier = origMtl.bumpMapAmount
	v.texmap_bump_on = origMtl.bumpMapEnable
	
	format "Converted to %\n" v to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Standardmaterial converted to "+v.name+":VrayMtl")) catch()
	return v
)

fn fR_Adv2Vray origMtl = (
	v=VRayMtl()
	v.name=origMtl.name
	v.refraction_affectShadows = on
	-- diffuse
	v.diffuse=origMtl.diffuseColor
	v.texmap_diffuse=origMtl.diffuseMap
	v.texmap_diffuse_on=origMtl.useDiffuseMap
	v.texmap_diffuse_multiplier=origMtl.diffuseMapAmount
	
	-- bump map
	v.texmap_bump=origMtl.bumpMap
	v.texmap_bump_on=origMtl.useBumpMap
	v.texmap_bump_multiplier=origMtl.bumpMapAmount
	
	-- displacement
	v.texmap_displacement=origMtl.MTDMap
	v.texmap_displacement_on=origMtl.useMTDMap
	v.texmap_displacement_multiplier=origMtl.MTDMapAmount

	-- reflection
	v.reflection=origMtl.reflectFilter
	v.texmap_reflection=origMtl.reflectMap
	v.texmap_reflection_on=origMtl.useReflectMap
	v.texmap_reflection_multiplier=origMtl.reflectMapAmount
	
	v.reflection_glossiness=1.0-sqr (origMtl.reflectGlossy*0.01)
	v.texmap_reflectionGlossiness=origMtl.reflectBlurryMap
	v.texmap_reflectionGlossiness_on=origMtl.useReflectBlurryMap
	v.texmap_reflectionGlossiness_multiplier=origMtl.reflectBlurryMapAmount
	
	v.reflection_subdivs=sqrt origMtl.reflectSamples
	v.reflection_fresnel=origMtl.useFresnel
	v.reflection_useInterpolation=origMtl.useReflBlur
	
	-- refraction
	v.refraction=origMtl.refractFilter
	v.texmap_refraction=origMtl.refractMap
	v.texmap_refraction_on=origMtl.useRefractMap
	v.texmap_refraction_multiplier=origMtl.refractMapAmount
	
	v.refraction_ior=origMtl.refractIOR
	v.texmap_refractionIOR=origMtl.refractIORMap
	v.texmap_refractionIOR_on=origMtl.useRefractIORMap
	v.texmap_refractionIOR_multiplier=origMtl.refractIORMapAmount
	
	v.refraction_glossiness=1.0-sqr (origMtl.refractGlossy*0.01)
	v.texmap_refractionGlossiness=origMtl.refractBlurryMap
	v.texmap_refractionGlossiness_on=origMtl.useRefractBlurryMap
	v.texmap_refractionGlossiness_multiplier=origMtl.refractBlurryMapAmount
	
	v.refraction_subdivs=sqrt origMtl.refractSamples
	v.refraction_useInterpolation=origMtl.useRefrBlur
	
	format "Converted to %\n" v to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":fR_Advanced converted to "+v.name+":VrayMtl")) catch()
	return v
)

fn fR_Metal2Vray origMtl = (
	v=VRayMtl()
	v.name=origMtl.name
	v.refraction_affectShadows = on
	v.diffuse=origMtl.diffuseColor
	v.texmap_diffuse=origMtl.diffuseMap
	v.texmap_diffuse_on=origMtl.diffuseMapEnable
	v.texmap_diffuse_multiplier=origMtl.diffuseMapAmount
	
	v.reflection=origMtl.reflectColor
	v.texmap_reflection=origMtl.reflectLevelMap
	v.texmap_reflection_on=origMtl.reflectLevelMapEnable
	v.texmap_reflection_multiplier=origMtl.reflectLevelMapAmount
	
	format "Converted to %\n" v to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":fR_Metal converted to "+s.name+":VrayMtl")) catch()
	return v
)

fn fR_Glass2Vray origMtl = (
	v=VRayMtl()
	v.name=origMtl.name
	v.refraction_affectShadows = on
	v.diffuse=origMtl.diffuseColor
	v.texmap_diffuse=origMtl.diffuseMap
	v.texmap_diffuse_on=origMtl.diffuseMapEnable
	v.texmap_diffuse_multiplier=origMtl.diffuseMapAmount

	v.reflection=origMtl.reflectColor
	v.reflection_fresnel=origMtl.useFresnel
	v.texmap_reflection=origMtl.reflectMap
	v.texmap_reflection_on=origMtl.reflectMapEnable
	v.texmap_reflection_multiplier=origMtl.reflectMapAmount
	
	v.refraction=origMtl.refractColor
	v.refraction_ior=origMtl.refractIOR
	v.texmap_refraction=origMtl.refractMap
	v.texmap_refraction_on=origMtl.refractMapEnable
	v.texmap_refraction_multiplier=origMtl.refractMapAmount
	
	v.refraction_affectShadows=true
	v.refraction_affectAlpha=true
	
	format "Converted to %\n" v to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":fR_Glass converted to "+s.name+":VrayMtl")) catch()
	return v
)

fn MW2Vray origmtl = (
	
	numcapas = fn_capasmaxwell origmtl
	format "Numcapas: %\n" numcapas to:templog
	if numcapas > 10 then numcapas=10
		
	--capa base (obligatoria)
	
	m = VRayBlendMtl ()
	m.name = origMtl.name
	maxwellMaterialSetActiveLayer material:origMtl layerIndex:0
	if origMtl.Use_Emitter == on then 
	(
		m.baseMtl = VRayLightMtl ()
		m.baseMtl.color = origMtl.Emitter_RGB_Color --de momento solo vale RGB
		m.baseMtl.multiplier = 30 --aproximaci髇
	) else
	(
		m.baseMtl = VrayMtl ()
		m.baseMtl.name = origMtl.Layer_name
		m.baseMtl.Diffuse = origMtl.BSDF_Reflected_Color
		m.baseMtl.texmap_diffuse = origMtl.BSDF_Reflected_Color_Texture
		m.baseMtl.texmap_bump_multiplier = origMtl.BSDF_Bump_Strength
		m.baseMtl.texmap_bump = origMtl.BSDF_Bump_Strength_Texture
		m.baseMtl.Refraction = origMtl.Transparency_Color
		m.baseMtl.texmap_opacity = origMtl.BSDF_Transparency_Color_Texture
		m.baseMtl.refraction_ior = origMtl.BSDF_Nd
		m.baseMtl.reflection_glossiness = (1-origMtl.BSDF_Roughness/100)
		if origMtl.BSDF_Roughness > 90 then m.baseMtl.Reflection = color 0 0 0 else 
		(
			m.baseMtl.Reflection = origMtl.Fresnel_Color
			m.baseMtl.reflection_fresnel = on
		)
		m.baseMtl.anisotropy = origMtl.BSDF_Anisotropy/100
		m.baseMtl.anisotropy_rotation = origMtl.BSDF_Anisotropy_Angle
		
	)

	--resto de capas
	if numcapas > 1 then
	(
		for i=1 to (numcapas-1) do
		(
			maxwellMaterialSetActiveLayer material:origMtl layerIndex:i
			m.coatMtl[i] = VrayMtl ()
			if ((origMtl.Use_Layer_Weight_Texture==on) and (origMtl.Layer_Weight_Texture!=undefined)) then
			(
				m.texmap_blend[i] = origMtl.Layer_Weight_Texture
				m.texmap_blend_multiplier[i] = origMtl.Layer_Weight
				val = origMtl.Layer_Weight*2.55
				m.Blend[i]= (color val val val)
			) else
			(
				val = origMtl.Layer_Weight*2.55
				m.Blend[i]= (color val val val)
			)
			m.coatMtl[i].name = origMtl.Layer_name
			m.coatMtl[i].Diffuse = origMtl.BSDF_Reflected_Color
			m.coatMtl[i].texmap_diffuse = origMtl.BSDF_Reflected_Color_Texture
			m.coatMtl[i].texmap_bump_multiplier = origMtl.BSDF_Bump_Strength
			m.coatMtl[i].texmap_bump = origMtl.BSDF_Bump_Strength_Texture
			m.coatMtl[i].Refraction = origMtl.Transparency_Color
			m.coatMtl[i].texmap_opacity = origMtl.BSDF_Transparency_Color_Texture
			m.coatMtl[i].refraction_ior = origMtl.BSDF_Nd
			m.coatMtl[i].reflection_glossiness = (1-origMtl.BSDF_Roughness/100)
			if origMtl.BSDF_Roughness > 90 then m.coatMtl[i].Reflection = color 0 0 0 else 
			(
				m.coatMtl[i].Reflection = origMtl.Fresnel_Color
				m.coatMtl[i].reflection_fresnel = on
			)
			m.coatMtl[i].anisotropy = origMtl.BSDF_Anisotropy/100
			m.coatMtl[i].anisotropy_rotation = origMtl.BSDF_Anisotropy_Angle
		)
	)
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Maxwell converted to "+m.name+":VrayMtl")) catch()
	return m
)

fn mrArchmaterial2Vray origMtl = (
	
	v=VRayMtl()
	v.name=origMtl.name
	v.refraction_affectShadows = on
	-- diffuse
	v.diffuse=origMtl.diff_color
	v.texmap_diffuse=origMtl.diff_color_map
	v.texmap_diffuse_on=origMtl.diff_color_map_on
	v.diffuse_roughness=origMtl.diff_rough
		
	-- bump map
	v.texmap_bump=origMtl.bump_map
	v.texmap_bump_on=origMtl.bump_map_on
	v.texmap_bump_multiplier=origMtl.bump_map_amt*100
	
	-- displacement
	v.texmap_displacement=origMtl.displacement_map
	v.texmap_displacement_on=origMtl.displacement_map_on
	v.texmap_displacement_multiplier=origMtl.displacement_map_amt*100

	-- reflection
	
	
	if (IDisplayGamma.colorCorrectionMode == #gamma) then
		(
			gam = IDisplayGamma.gamma
			v.reflection=origMtl.refl_color*((origMtl.refl_weight)^gam)  --aplicamos la correcci髇 gamma al valor de reflejo de vray
		) 
		else ( v.reflection = origMtl.refl_color*origMtl.refl_weight)
			
	v.texmap_reflection=origMtl.refl_color_map
	v.texmap_reflection_on=origMtl.refl_color_map_on
	v.texmap_reflection_multiplier=origMtl.refl_weight*100
	v.reflection_glossiness=origMtl.refl_gloss
	v.texmap_reflectionGlossiness=origMtl.refl_gloss_map
	v.texmap_reflectionGlossiness_on=origMtl.refl_gloss_map_on
	v.texmap_reflectionGlossiness_multiplier=origMtl.refl_gloss*100
	v.reflection_subdivs=origMtl.refl_samples
	if (origMtl.refl_func_fresnel == on) then	
		(
			v.reflection_fresnel=on
			v.reflection_lockIOR = off
			v.reflection_ior = origMtl.refr_ior
		)
	v.reflection_useInterpolation=origMtl.refl_interp
	
	-- refraction
	
	if (IDisplayGamma.colorCorrectionMode == #gamma) then
		(
			gam = IDisplayGamma.gamma
			v.refraction=origMtl.refr_color*((origMtl.refr_weight)^gam)  --aplicamos la correcci髇 gamma al valor de refracci髇 de vray
		) 
	else ( v.refraction = origMtl.refr_color*origMtl.refr_weight)
	v.texmap_refraction=origMtl.refr_color_map
	v.texmap_refraction_on=origMtl.refr_color_map_on
	v.texmap_refraction_multiplier=origMtl.refr_weight*100
	
	v.refraction_ior=origMtl.refr_ior
	v.texmap_refractionIOR=origMtl.refr_ior_map
	v.texmap_refractionIOR_on=origMtl.refr_ior_map_on 
		
	v.refraction_glossiness=origMtl.refr_gloss
	v.texmap_refractionGlossiness=origMtl.refr_gloss_map
	v.texmap_refractionGlossiness_on=origMtl.refr_gloss_map_on
	
	v.refraction_subdivs=origMtl.refr_samples
	v.refraction_useInterpolation=origMtl.refr_interp
		
	--cutout
	v.texmap_opacity_on = origMtl.cutout_map_on
	v.texmap_opacity = origMtl.cutout_map
		
	--translucency
		
	--anisotropy
	v.anisotropy_derivation = origMtl.aniso_mode
	v.anisotropy = 1-origMtl.anisotropy
	v.anisotropy_rotation = origMtl.anisoangle*360
	
	format "Converted to %\n" v to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+v.name+":VrayMtl")) catch()
	return v
	) 
	


---------------------------------------------------------------
--  FUNCIONES PARA CONVERTIR A MAXWELL 1.7 --
---------------------------------------------------------------
fn salvaproc MapaOrig = (
	rdn = random 1 9999 as string
nomproc = MapaOrig.name
rbm = renderMap MapaOrig size:[anchoproc,altoproc]
rbm.filename = dirproc + "\\" + nomproc + rdn + extension
format "Generate map % ...\n" rbm.filename to:templog
save rbm
nuevoproc = Bitmaptexture ()
nuevoproc.filename = rbm.filename
nuevoproc.name = nomproc
close rbm
return nuevoproc
)

fn convierte_mapas MapaOrig = (
	try
	(
	mapain = openbitmap MapaOrig.filename
	
	mapaout = mapain
	
	ext = getFilenameType mapain.filename
	
	if ((ext != ".jpg") and (ext != ".png") and (ext != "bmp")) then
	(	
		pt = getFilenamePath mapain.filename
		nom = getFilenameFile mapain.filename
		mapaout.filename = pt + nom + extension
		
		
		if mapdir then
		(
			
			mapaout.filename = dir +"\\" + nom + extension
			save mapaout
			
		) else
		(
			
			save mapaout
			close mapaout
			
		)

		format "Converting map % to % \n" mapaorig.filename mapaout.filename to:templog

	) else
	(
		mapaout.filename = mapain.filename
	)
		
	MapaOrig.filename = mapaout.filename
	format "There is no need to convert map % \n" mapaorig.filename to:templog

	) catch
	(
		format "File % not found \n" MapaOrig.filename to:templog
	)
	)

fn ValidaMapa MapaOrig = (
	
	mapa = classof MapaOrig
	if (mapa == UndefinedClass) then
		(
			return undefined
		)	
	if (mapa == RGB_Tint) then
		(
			return ValidaMapa MapaOrig.map1
		) 
	if (mapa == Bitmaptexture) then
		(
			try(if ((mapa.apply) and (mapa.cropPlace==0)) then return rendercrop mapa else return MapaOrig	) catch(return MapaOrig)		
		)
		
	else
	(
		return undefined
	)
	
	
	
)

fn std2MW origMtl = (

	m=MaxwellMaterial ()
	m.name=origMtl.name

	--difuso
	m.BSDF_Reflected_Color = origMtl.diffuse
	m.BSDF_Reflected_Color_Texture = ValidaMapa origMtl.diffuseMap
	m.BSDF_Reflected_Color_Use_Texture = origMtl.diffuseMapEnable
	
	--bump
	m.BSDF_Bump_Strength_Texture = ValidaMapa origMtl.bumpMap
	m.BSDF_Bump_Strength_Use_Texture = origMtl.bumpMapEnable
	m.BSDF_Bump_Strength = origMtl.bumpMapAmount

	--clipmaps
	m.BSDF_Transparency_Color_Texture = ValidaMapa origMtl.opacityMap
	m.BSDF_Transparency_Color_Use_Texture = origMtl.opacityMapEnable
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Standardmaterial converted to "+s.name+":Maxwell_1.7")) catch()
	return m
)

fn mrArchmaterial2MW origMtl = (
	
	m = MaxwellMaterial ()
	m.name=origMtl.name
		
	--difuso
	m.BSDF_Reflected_Color = origMtl.diff_color
	m.BSDF_Reflected_Color_Texture = ValidaMapa origMtl.diff_color_map
	m.BSDF_Reflected_Color_Use_Texture = origMtl.diff_color_map_on
	
	--bump
	m.BSDF_Bump_Strength_Texture = ValidaMapa origMtl.bump_map
	m.BSDF_Bump_Strength_Use_Texture = origMtl.bump_map_on
	m.BSDF_Bump_Strength = origMtl.bump_map_amt*100
	
	--refraccion
	
	
	if (origMtl.refr_weight>0) then 
		(
			m.BSDF_Transparency_Color_Texture = ValidaMapa origMtl.refr_color_map
			m.Transparency_Color = origMtl.refr_color
			m.BSDF_Nd = origMtl.refr_ior -- si es negro, mejor el valor por defecto de maxwell
			m.BSDF_Roughness = (1-origMtl.refraction_glossiness)*100 --entre lambertian y esto...pues esto (de momento)
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+s.name+":Maxwell_1.7")) catch()
		return m
		) 
	
	--clipmaps 
	if origMtl.cutout_map != undefined then --clipmap 2 capas con pesos
	(
		--vamos con la capa 1
		
		m.Layer_name = (m.name+"_base")
		m.Layer_Weight = 100
		m.BSDF_Nd = 3
		m.Layer_Weight_Texture = ValidaMapa origMtl.cutout_map
		m.Use_Layer_Weight_Texture = on
		m.Layer_Weight_Texture.output.invert = off
		m.BSDF_Roughness = 100
		m.Transparency_Color = color 0 0 0
		
		--pasamos a la segunda capa
		maxwellMaterialAddLayer material:m name:(m.name+"_clipmap")
		maxwellMaterialSetActiveLayer material:m layerIndex:1
		m.Layer_Weight = 100
		m.BSDF_Nd = 1
		tt=ValidaMapa origMtl.cutout_map
		m.Layer_Weight_Texture = copy tt --para evitar que haga una instancia del de la otra capa
		m.Use_Layer_Weight_Texture = on
		m.Layer_Weight_Texture.output.invert = on
		m.BSDF_Roughness = 100
		m.Transparency_Color = color 255 255 255
	)
	
	--reflexi髇
		
	if ((origMtl.refl_weight>0.8 and origMtl.refr_ior>3 and origMtl.refl_color_map == undefined) or (origMtl.refl_metal == on)) then --es un metal
	(
		m.BSDF_Roughness = (1-origMtl.refl_gloss)*100
		m.BSDF_Nd = 20
		m.BSDF_Anisotropy = (1-origMtl.anisotropy)*100 
		m.BSDF_Anisotropy_Angle = origMtl.anisoangle*360
		m.BBSDF_Anisotropy_Texture = origMtl.anisotropy_map --a alguien se le ha escapado una B
		m.BSDF_Anisotropy_Angle_Texture = origMtl.anisoangle_map
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+s.name+":Maxwell_1.7")) catch()
	return m
	)
		
	if (origMtl.refl_weight>0) then --plastico, 2 capas
	(
		m.Layer_name = (m.name+"_base")
		m.Layer_Weight = 100-(origMtl.refl_weight*100.0)
		if m.Layer_Weight < 70 then m.Layer_Weight = 70 --aproximando a鷑
		capa = m.Layer_Weight
		m.BSDF_Roughness = 100
		
		--pasamos a la segunda capa
		maxwellMaterialAddLayer material:m name:(m.name+"_refl")
		m.Layer_Weight = 100.0 - capa
		m.BSDF_Reflected_Color = origMtl.refl_color*origMtl.refl_weight
		m.BSDF_Roughness = (1-origMtl.refl_gloss)*100
		m.BSDF_Anisotropy = (1-origMtl.anisotropy)*100 
		m.BSDF_Anisotropy_Angle = origMtl.anisoangle*360
		m.BBSDF_Anisotropy_Texture = origMtl.anisotropy_map --a alguien se le ha escapado una B
		m.BSDF_Anisotropy_Angle_Texture = origMtl.anisoangle_map
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+s.name+":Maxwell_1.7")) catch()
	return m
	) 
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+s.name+":Maxwell_1.7")) catch()
	return m
) --fin de la funcion mrArchmaterial2MW

fn convertir_Vray_MW origMtl = (

	m = MaxwellMaterial ()
	m.name=origMtl.name
		
	--difuso
	m.BSDF_Reflected_Color = origMtl.diffuse
	origMap = origMtl.texmap_diffuse
	m.BSDF_Reflected_Color_Texture = ValidaMapa origMap
	m.BSDF_Reflected_Color_Use_Texture = origMtl.texmap_diffuse_on
	
	--bump
	m.BSDF_Bump_Strength_Texture = ValidaMapa origMtl.texmap_bump
	m.BSDF_Bump_Strength_Use_Texture = origMtl.texmap_bump_on
	m.BSDF_Bump_Strength = origMtl.texmap_bump_multiplier
	
	--refraccion
	rfr = origMtl.refraction
	m.Transparency_Color = rfr
	
	if (rfr.r>0 or rfr.g>0 or rfr.b>0) then 
		(
			if crisnegros then 
				(
					if (m.BSDF_Reflected_Color.value < 10) then (m.BSDF_Reflected_Color = color 230 230 230)
				)
			m.BSDF_Nd = origMtl.refraction_ior -- si es negro, mejor el valor por defecto de maxwell
			m.BSDF_Roughness = (1-origMtl.refraction_glossiness)*100 --entre lambertian y esto...pues esto (de momento)
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+s.name+":Maxwell_1.7")) catch()
		return m
		) 
	
	--clipmaps 
	
	m.BSDF_Transparency_Color_Texture = ValidaMapa origMtl.texmap_opacity
	m.BSDF_Transparency_Color_Use_Texture = origMtl.texmap_opacity_on
		
	--reflexi髇
	rfl = origMtl.reflection
	fresn = not origMtl.reflection_fresnel
	if (rfl.r>150 and rfl.g>150 and rfl.b>150 and fresn and origMap == undefined) then --es un metal
	(
		m.BSDF_Roughness = (1-origMtl.reflection_glossiness)*100
		m.BSDF_Nd = 20
		m.BSDF_Anisotropy = abs (origMtl.anisotropy*100) --evitando negativos, que dar韆n 0
		m.BSDF_Anisotropy_Angle = abs ( mod origMtl.anisotropy_rotation 360) --en vray se puede pasar de 360, y dar韆 360
		m.BBSDF_Anisotropy_Texture = origMtl.texmap_anisotropy --a alguien se le ha escapado una B
		m.BSDF_Anisotropy_Angle_Texture = origMtl.texmap_anisotropy_rotation
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+s.name+":Maxwell_1.7")) catch()
	return m
	)
		
	if (rfl.r>0 and rfl.g>0 and rfl.b>0) then --plastico, 2 capas
	(
		m.Layer_name = (m.name+"_base")
		m.Layer_Weight = 100-(rfl.value*100.0/255)
		if m.Layer_Weight < 70 then m.Layer_Weight = 70 --aproximando a鷑
		capa = m.Layer_Weight
		m.BSDF_Roughness = 100
		
		--pasamos a la segunda capas
		maxwellMaterialAddLayer material:m name:(m.name+"_refl")
		m.Layer_Weight = 100.0 - capa
		m.BSDF_Reflected_Color = origMtl.reflection
		m.BSDF_Roughness = (1-origMtl.reflection_glossiness)*100
		m.BSDF_Anisotropy = abs (origMtl.anisotropy*100) --evitando negativos, que dar韆n 0
		m.BSDF_Anisotropy_Angle = abs ( mod origMtl.anisotropy_rotation 360) --en vray se puede pasar de 360, y dar韆 360
		m.BBSDF_Anisotropy_Texture = origMtl.texmap_anisotropy --a alguien se le ha escapado una B
		m.BSDF_Anisotropy_Angle_Texture = origMtl.texmap_anisotropy_rotation
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+s.name+":Maxwell_1.7")) catch()
	return m
	) 
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+s.name+":Maxwell_1.7")) catch()
	return m
) --fin de la funcion convertir_Vray_MW

fn vraylight2MW_emitter origMtl = (

	m = MaxwellMaterial ()
	m.name = origMtl.name
	m.Use_Emitter = on
	m.Emitter_RGB_Color = origMtl.color
	m.Emitter_luminance_type = 1
	m.Emitter_unit = 0
	m.Emitter_Luminance = origMtl.multiplier*200 --aproximando aun
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayLight converted to "+s.name+":Maxwell_1.7_emitter")) catch()
	return m	
)


---------------------------------------------------------------
--  FUNCIONES PARA CONVERTIR A MAXWELL 2.x --
---------------------------------------------------------------
fn fn_fullpath ruta=(
	ruta=(mapPaths.getFullFilePath ruta)
	ruta
)

fn salvaproc MapaOrig = (
	rdn = random 1 9999 as string
	nomproc = MapaOrig.name
	rbm = renderMap MapaOrig size:[anchoproc,altoproc]
	rbm.filename = dirproc + "\\" + nomproc + rdn + extension
	format "Generate map % ...\n" rbm.filename to:templog
	save rbm
	nuevoproc = Bitmaptexture ()
	nuevoproc.filename = rbm.filename
	nuevoproc.name = nomproc
	close rbm
	return nuevoproc
)

fn convierte_mapas MapaOrig = (
	try
	(
	mapain = openbitmap MapaOrig.filename
	
	mapaout = mapain
	
	ext = getFilenameType mapain.filename
	
	if ((ext != ".jpg") and (ext != ".png") and (ext != "bmp")) then
	(	
		pt = getFilenamePath mapain.filename
		nom = getFilenameFile mapain.filename
		mapaout.filename = pt + nom + extension
		
		
		if mapdir then
		(
			
			mapaout.filename = dir +"\\" + nom + extension
			save mapaout
			
		) else
		(
			
			save mapaout
			close mapaout
			
		)

		format "Converting map % to % \n" mapaorig.filename mapaout.filename to:templog

	) else
	(
		mapaout.filename = mapain.filename
	)
		
	MapaOrig.filename = mapaout.filename
	format "There is no need to convert map % \n" mapaorig.filename to:templog

	) catch
	(
		format "File % not found \n" MapaOrig.filename to:templog
	)
	)

fn ValidaMapa2 MapaOrig = (
	
	mapa = classof MapaOrig
	if (mapa == UndefinedClass) then
		(
			return undefined
		)	
	if (mapa == RGB_Tint) then
		(
			return ValidaMapa2 MapaOrig.map1
		) 
	if (mapa == Bitmaptexture) then return MapaOrig
	
	else
		(
			if procedural then 
			(
				return salvaproc MapaOrig
			) 
			else
			(
				return undefined
			)
		)
		
	)

fn std2MW2 origMtl = (

	m=Maxwell_Material ()
	m.name=origMtl.name

	--difuso
	m.layers[1].bsdfs[1].ReflectedColor = origMtl.diffuse
	if origMtl.diffuseMapEnable = on then 
		(	
			mapaold = ValidaMapa2 origMtl.diffuseMap
			if mapaold != undefined then
			(
				mapa = Maxwell_Bitmap()
				m.layers[1].bsdfs[1].ReflectedColorTexture = mapa
				m.layers[1].bsdfs[1].ReflectedColorTexture.filename = mapaold.filename
			)
		)
		
	--bump
	if origMtl.bumpMapEnable = on then m.layers[1].bsdfs[1].BumpStrengthTexture = ValidaMapa2 origMtl.bumpMap
	m.layers[1].bsdfs[1].BumpStrength = origMtl.bumpMapAmount

	--clipmaps
	if origMtl.opacityMapEnable = on then m.layers[1].bsdfs[1].TransparencyColorTexture = ValidaMapa2 origMtl.opacityMap
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Standardmaterial converted to "+m.name+":Maxwell_Material")) catch()
	return m
)

fn mrArchmaterial2MW2 origMtl = (
	
	m = Maxwell_Material ()
	m.name=origMtl.name
		
	--difuso
	m.layers[1].bsdfs[1].ReflectedColor = origMtl.diff_color
	if ((origMtl.diff_color_map_on == true) and (origMtl.diff_color_map!= undefined)) then 
	(
		a=ValidaMapa2 origMtl.diff_color_map_on
		map=maxwellbitmap()
		map.filename=a.filename
		m.layers[1].bsdfs[1].ReflectedColorTexture = map		
	)
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--bump
	if ((origMtl.bump_map_on == true) and (origMtl.bump_map!= undefined)) then 
	(
		a=ValidaMapa2 origMtl.bump_map
		map=maxwellbitmap()
		map.filename=a.filename
		m.layers[1].bsdfs[1].BumpStrengthTexture = map
		m.layers[1].bsdfs[1].BumpStrength = origMtl.bump_map_amt*100		
	)
	
	--refraccion	
	if (origMtl.refr_weight>0) then 
		(
			if (origMtl.refr_color_map!= undefined) then 
			(
				a=ValidaMapa2 origMtl.refr_color_map
				map=maxwellbitmap()
				map.filename=a.filename
				m.layers[1].bsdfs[1].TransparencyColorTexture = map
			)
			m.Transparency_Color = origMtl.refr_color
			m.layers[1].bsdfs[1].Nd = origMtl.refr_ior -- si es negro, mejor el valor por defecto de maxwell
			m.layers[1].bsdfs[1].Roughness = (1-origMtl.refraction_glossiness)*100 --entre lambertian y esto...pues esto (de momento)
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+m.name+":Maxwell_Material")) catch()
		return m
		) 
	
	--clipmaps 
	if origMtl.cutout_map != undefined then --clipmap 2 capas con pesos
	(
		a=ValidaMapa2 origMtl.cutout_map
		map=maxwellbitmap()
		map.filename=a.filename
		m.layers[1].Mask = map
	)
	
	--reflexi髇
		
	if ((origMtl.refl_weight>0.8 and origMtl.refr_ior>3 and origMtl.refl_color_map == undefined) or (origMtl.refl_metal == on)) then --es un metal
	(
		m.layers[1].bsdfs[1].Roughness = (1-origMtl.refl_gloss)*100
		m.layers[1].bsdfs[1].nd = 20
		m.layers[1].bsdfs[1].Anisotropy = (1-origMtl.anisotropy)*100 
		m.layers[1].bsdfs[1].AnisotropyAngle = origMtl.anisoangle*360
		if (origMtl.anisotropy_map!= undefined) then 
		(
			a=ValidaMapa2 origMtl.anisotropy_map
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[1].AnisotropyTexture = map
		)
		if (origMtl.anisoangle_map!= undefined) then 
		(
			a=ValidaMapa2 origMtl.anisoangle_map
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[1].AnisotropyAngleTexture = map
		)
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+m.name+":Maxwell_Material")) catch()
	return m
	)
		
	if (origMtl.refl_weight>0) then --plastico, 2 capas
	(
		m.Layers[1].bsdfs.count=2
		m.Layers[1].bsdfs[1].name = (m.name+"_base")
		m.Layers[1].bsdfs[2].name = (m.name+"_refl")
		m.Layers[1].bsdfs[1].SurfaceWeight = 100-(origMtl.refl_weight*100.0)
		if m.Layers[1].bsdfs[1].SurfaceWeight < 70 then m.Layers[1].bsdfs[1].SurfaceWeight = 70 --aproximando a鷑
		capa = m.Layers[1].bsdfs[1].SurfaceWeight
		m.Layers[1].bsdfs[1].Roughness = 100
		
		--pasamos a la segunda capa
		m.Layers[1].bsdfs[2].SurfaceWeight = 100.0 - capa
		m.layers[1].bsdfs[2].ReflectedColor = origMtl.refl_color*origMtl.refl_weight
		m.Layers[1].bsdfs[2].Roughness = (1-origMtl.refl_gloss)*100
		m.Layers[1].bsdfs[2].Anisotropy = (1-origMtl.anisotropy)*100 
		m.Layers[1].bsdfs[2].AnisotropyAngle = origMtl.anisoangle*360
		if (origMtl.anisotropy_map!= undefined) then 
		(
			a=ValidaMapa2 origMtl.anisotropy_map
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[2].AnisotropyTexture = map
		)
		if (origMtl.anisoangle_map!= undefined) then 
		(
			a=ValidaMapa2 origMtl.anisoangle_map
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[2].AnisotropyAngleTexture = map
		)
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+m.name+":Maxwell_Material")) catch()
	return m
	) 
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+m.name+":Maxwell_Material")) catch()
	return m
) --fin de la funcion mrArchmaterial2MW

fn convertir_Vray_MW2 origMtl = (

	m = Maxwell_Material ()
	m.name=origMtl.name
		
	--difuso
	m.layers[1].bsdfs[1].ReflectedColor = origMtl.diffuse
	if ((origMtl.texmap_diffuse_on == true) and (origMtl.texmap_diffuse!= undefined)) then 
	(
		a=ValidaMapa2 origMtl.texmap_diffuse
		map=maxwellbitmap()
		map.filename=a.filename
		m.layers[1].bsdfs[1].ReflectedColorTexture = map		
	)
	
	--bump
	if ((origMtl.texmap_bump_on == true) and (origMtl.texmap_bump!= undefined)) then 
	(
		a=ValidaMapa2 origMtl.texmap_bump
		map=maxwellbitmap()
		map.filename=a.filename
		m.layers[1].bsdfs[1].BumpStrengthTexture = map
		m.layers[1].bsdfs[1].BumpStrength = origMtl.texmap_bump_multiplier		
	)
	
	--refraccion
	rfr = origMtl.refraction
	m.layers[1].bsdfs[1].TransparencyColor = rfr
	
	if (rfr.r>0 or rfr.g>0 or rfr.b>0) then 
		(
			if crisnegros then 
				(
					if (m.layers[1].bsdfs[1].ReflectedColor.value < 10) then (m.layers[1].bsdfs[1].ReflectedColor = color 230 230 230)
				)
			m.layers[1].bsdfs[1].nd = origMtl.refraction_ior -- si es negro, mejor el valor por defecto de maxwell
			m.layers[1].bsdfs[1].roughness = (1-origMtl.refraction_glossiness)*100 --entre lambertian y esto...pues esto (de momento)
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+m.name+":Maxwell_Material")) catch()
		return m
		) 
	
	--clipmaps 
	if ((origMtl.texmap_opacity_on == true) and (origMtl.texmap_opacity!= undefined)) then 
	(
		a=ValidaMapa2 origMtl.texmap_opacity
		map=maxwellbitmap()
		map.filename=a.filename
		m.layers[1].Mask = map
	)
		
	--reflexi髇
	rfl = origMtl.reflection
	fresn = not origMtl.reflection_fresnel
	if (rfl.r>150 and rfl.g>150 and rfl.b>150 and fresn and origMap == undefined) then --es un metal
	(
		m.layers[1].bsdfs[1].Roughness = (1-origMtl.reflection_glossiness)*100
		m.layers[1].bsdfs[1].Nd = 20
		m.layers[1].bsdfs[1].Anisotropy = abs (origMtl.anisotropy*100) --evitando negativos, que dar韆n 0
		m.layers[1].bsdfs[1].AnisotropyAngle = abs ( mod origMtl.anisotropy_rotation 360) --en vray se puede pasar de 360, y dar韆 360
		if (origMtl.texmap_anisotropy!= undefined) then 
		(
			a=ValidaMapa2 origMtl.texmap_anisotropy
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[1].AnisotropyTexture = map
		)
		if (origMtl.texmap_anisotropy_rotation!= undefined) then 
		(
			a=ValidaMapa2 origMtl.texmap_anisotropy_rotation
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[1].AnisotropyAngleTexture = map
		)
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+m.name+":Maxwell_Material")) catch()
	return m
	)
		
	if (rfl.r>0 and rfl.g>0 and rfl.b>0) then --plastico, 2 capas
	(
		m.Layers[1].bsdfs.count=2
		m.Layers[1].bsdfs[1].name = (m.name+"_base")
		m.Layers[1].bsdfs[2].name = (m.name+"_refl")
		m.Layers[1].bsdfs[1].SurfaceWeight = 70 --aproximando a鷑
		capa = m.Layers[1].bsdfs[1].SurfaceWeight
		m.Layers[1].bsdfs[1].Roughness = 100
		
		--pasamos a la segunda capas
		m.Layers[1].bsdfs[2].SurfaceWeight = 100.0 - capa
		m.layers[1].bsdfs[2].ReflectedColor = origMtl.reflection
		m.Layers[1].bsdfs[2].Roughness = (1-origMtl.reflection_glossiness)*100
		m.layers[1].bsdfs[2].Anisotropy = abs (origMtl.anisotropy*100) --evitando negativos, que dar韆n 0
		m.layers[1].bsdfs[2].AnisotropyAngle = abs ( mod origMtl.anisotropy_rotation 360) --en vray se puede pasar de 360, y dar韆 360
		if (origMtl.texmap_anisotropy!= undefined) then 
		(
			a=ValidaMapa2 origMtl.texmap_anisotropy
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[2].AnisotropyTexture = map
		)
		if (origMtl.texmap_anisotropy_rotation!= undefined) then 
		(
			a=ValidaMapa2 origMtl.texmap_anisotropy_rotation
			map=maxwellbitmap()
			map.filename=a.filename
			m.layers[1].bsdfs[2].AnisotropyAngleTexture = map
		)
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+m.name+":Maxwell_Material")) catch()
	return m
	) 
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+m.name+":Maxwell_Material")) catch()
	return m
) --fin de la funcion convertir_Vray_MW

fn vraylight2MW2_emitter origMtl = (

	m = Maxwell_Material ()
	m.name = origMtl.name
	m.Use_Emitter = on
	m.Emitter_RGB_Color = origMtl.color
	m.Emitter_luminance_type = 1
	m.Emitter_unit = 0
	m.Emitter_Luminance = origMtl.multiplier*200 --aproximando aun
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayLightMtl converted to "+m.name+":Maxwell_Emiter")) catch()
	return m	
)


--------------------------------------------------------------
---FUNCIONES PARA CONVERTIR A MENTAL RAY---
--------------------------------------------------------------

fn ValidaMapaMental MapaOrig = (
	
	mapa = classof MapaOrig
	if (mapa == UndefinedClass) then
		(
			return undefined
		)	
	if (mapa == Bitmaptexture) then
		
			(
				return MapaOrig
			)
	if (mapa == RGB_Tint) then
		(
			mr = RGB_Tint()
			mr.red = mapaorig.red
			mr.green = mapaorig.green
			mr.blue = mapaorig.blue
			mr.map1 = ValidaMapaMental MapaOrig.map1
			return mr
		) 
	if (mapa == Color_Correction) then
		(
			mr = MapaOrig			
			mr.map = ValidaMapaMental MapaOrig.map
			return mr
		) 
	if (mapa == VRayDirt) then
		(
			m = Ambient_Reflective_Occlusion__3dsmax()
			m.samples = MapaOrig.subdivs
			m.bright = MapaOrig.unoccluded_color
			m.dark = MapaOrig.occluded_color
			m.spread = MapaOrig.distribution
			m.max_distance = MapaOrig.radius
		return m
		)
	if (mapa == mix) then
		(
			mx = mix()
			mx.map1 = ValidaMapaMental mapaOrig.map1
			mx.map2 = ValidaMapaMental mapaOrig.map2
			mx.Mask = ValidaMapaMental mapaOrig.mask
			return mx
		)
	if (mapa == CompositeTexturemap) then
		(
			if mapaorig.maplist.count >0 then
			(
				for i = 1 to mapaorig.maplist.count do (mapaorig.maplist[i] = ValidaMapaMental mapaorig.maplist[i])
			)
		)
	if (mapa == VRayBmpFilter) then
		(
			return ValidaMapaMental mapaorig.bitmap
		)
	if (mapa == VRaySky) then 
		(
			m = mr_Physical_Sky
			return m
		)
	return mapaorig
		
)

fn vray2mrArchmaterial origmtl= (			
				
				m = Arch___Design__mi ()
				m.name = origmtl.name
				
				m.diff_color = origmtl.Diffuse
				if (origmtl.texmap_diffuse != undefined AND origmtl.texmap_diffuse_on) then 
				(				
					m.diff_color_map = ValidaMapaMental origmtl.texmap_diffuse
					m.diff_weight    = origmtl.texmap_diffuse_multiplier / 100
				)
				else
					m.diff_weight = 1.0 				
				
				m.refl_color = origmtl.Reflection
				if (origmtl.texmap_reflection != undefined AND origmtl.texmap_reflection_on) then 
				(
					m.refl_color_map = ValidaMapaMental origmtl.texmap_reflection
					m.refl_weight    = origmtl.texmap_reflection_multiplier / 100
				)
				else
					m.refl_weight = origmtl.Reflection.value/255				
				
				m.refl_gloss = origmtl.reflection_glossiness*0.9
				m.refl_gloss_map = ValidaMapaMental origmtl.texmap_reflectionGlossiness
				m.refl_gloss_map_on = origmtl.texmap_reflectionGlossiness_on				
				m.refl_samples = origmtl.reflection_subdivs
				m.refl_interp = origmtl.reflection_useInterpolation
				m.refl_func_fresnel = origmtl.reflection_fresnel
				
				if (not m.refl_func_fresnel) do
				(
				    m.refl_func_low = 1.0 - ((origmtl.Diffuse.r + origmtl.Diffuse.g + origmtl.Diffuse.b) / 4.0)
					if (m.refl_func_low < 0.2) then m.refl_func_low = 0.2
				)
							
				m.refr_color = origmtl.Refraction
				
				if (origmtl.texmap_refraction != undefined AND origmtl.texmap_refraction_on) then 
				(
					m.refr_color_map = ValidaMapaMental origmtl.texmap_refraction
					m.refr_weight    = origmtl.texmap_refraction_multiplier / 100
				)
				else
					m.refr_weight = origmtl.Refraction.value/255 
					
				m.refr_gloss        = origmtl.refraction_glossiness
				m.refr_gloss_map    = ValidaMapaMental origmtl.texmap_refractionGlossiness
				m.refr_gloss_map_on = origmtl.texmap_refractionGlossiness_on
				
				m.refr_samples   = origmtl.refraction_subdivs
				m.refr_ior       = origmtl.refraction_ior
				m.refr_ior_map   = origmtl.texmap_refractionIOR
				
				if (not origmtl.reflection_lockIOR) do
				(
					-- turn fresnel func off
					m.refl_func_fresnel = false
				    -- approximate separate reflection IOR with "func low"
					m.refl_func_low = origmtl.reflection_ior / 20
					-- make sure below 1.0
					if (m.refl_func_low > 1.0) then m.refl_func_low = 1.0
				)
				
				
				m.refr_transc  = origmtl.translucency_color
				m.refr_transc_map = ValidaMapaMental origmtl.texmap_translucent
				m.refr_transc_map_on = origmtl.texmap_translucent_on
				
				m.anisotropy    = 1.0 - origmtl.anisotropy
				m.anisoangle    = (origmtl.anisotropy_rotation / 360)+0.25
				
				m.aniso_mode    = origmtl.anisotropy_derivation
				m.aniso_channel = origmtl.anisotropy_channel
				
				m.refl_hlonly   = not origmtl.option_traceReflection
			    m.opts_1sided   = not origmtl.option_doubleSided				
				m.opts_skip_inside = not origmtl.option_reflectOnBack

				m.refl_cutoff = origmtl.option_cutOff
                m.refr_cutoff = origmtl.option_cutOff
    
				
				m.refr_falloff_color = origmtl.refraction_fogColor
				m.refr_falloff_dist  = origmtl.translucency_thickness

				m.bump_map     = ValidaMapaMental origmtl.texmap_bump
				m.bump_map_amt = origmtl.texmap_bump_multiplier / 100
				m.bump_map_on  = origmtl.texmap_bump_on
				

				m.displacement_map     = ValidaMapaMental origmtl.texmap_displacement
				m.displacement_map_amt = origmtl.texmap_displacement_multiplier / 100
				m.displacement_map_on  = origmtl.texmap_displacement_on
				
				
				m.cutout_map        = ValidaMapaMental origmtl.texmap_opacity
				m.cutout_map_on     = origmtl.texmap_opacity_on
				--m.refr_trans_on = mtl.translucency_on   ahora tiene 3 valores en vray
				
				format "Converted to %\n" m to:templog
				try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+m.name+":Arch___Design__mi")) catch()
				return m
			)

fn std2mrArchmaterial origmtl= (				
				
				m = Arch___Design__mi ()
				m.name = origmtl.name
				m.opts_backface_cull = not origmtl.twosided 
				
				
				--- difuso
				m.diff_color = origmtl.Diffuse				
				m.diff_color_map = origmtl.diffuseMap
				m.diff_weight    = origmtl.diffuseMapAmount/ 100
				m.diff_color_map_on = origmtl.diffuseMapEnable
		
				--- bump
				m.bump_map = origmtl.bumpMap
				m.bump_map_on = origmtl.bumpMapEnable					
				m.bump_map_amt = origmtl.bumpMapAmount/100	
				
				--- refl
				m.refl_color = origmtl.specular
				m.refl_color_map = origmtl.specularMap
				m.refl_color_map_on = origmtl.specularMapEnable
				m.refl_weight = origmtl.specularMapAmount/ 100
				m.refl_weight = origmtl.specularLevel/100

				--- glossy
				m.refl_gloss = origmtl.glossiness/100
				m.refl_gloss_map = origmtl.glossinessMap
				m.refl_gloss_map_on = origmtl.glossinessMapEnable
				
				format "Converted to %\n" m to:templog
				try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Standardmaterial converted to "+m.name+":Arch___Design__mi")) catch()
				return m

			)

fn MW2mrArchmaterial origmtl = (
	
	numcapas = fn_capasmaxwell_old origmtl
	
	if numcapas == 2 then --se toman s髄o 2 como m醲imo
	(
		m = Blend()
		m.name = origMtl.name
		a = m.map1 = Arch___Design__mi ()
		b = m.map2 = Arch___Design__mi ()
		
		--primera capa
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:0
		peso_A = origMtl.Layer_Weight
		a.name = origMtl.Layer_name
		if origMtl.Use_Emitter == on then --solo se tiene en cuenta color+luminancia
		(
			a.self_illum_on = on
			if origMtl.Emitter_color_type == 0 then 
			(
				a.self_illum_color_mode = off
				a.self_illum_color_filter = origMtl.Emitter_RGB_Color
			) 
			else
				(
					a.self_illum_color_mode = on
					a.self_illum_color_kelvin = origMtl.Emitter_Correlated_Color
				)
			if origMtl.Emitter_luminance_type == 0 then
			(
				a.self_illum_int_mode = on
				a.self_illum_int_arbitrary = origMtl.Emitter_Watts/40 --usamos como valor base 40W
			) --mirar las equivalencias para los valores f韘icos con illum_int_mode off
			
		) else
		(
			a.diff_color = origMtl.BSDF_Reflected_Color
			a.diff_color_map = origMtl.BSDF_Reflected_Color_Texture
			a.bump_map_amt = origMtl.BSDF_Bump_Strength/100
			a.bump_map = origMtl.BSDF_Bump_Strength_Texture
			if origMtl.Transparency_Color.value > 0 then 
			(
				a.refr_falloff_on = on
				a.refr_falloff_color_on = on
				a.refr_falloff_dist = origMtl.BSDF_Absorption/100
				a.refr_falloff_color = origMtl.Transparency_Color
				a.refr_weight = origMtl.Transparency_Color.value/255
			)
				
			a.cutout_map = origMtl.BSDF_Transparency_Color_Texture
			a.refr_ior = origMtl.BSDF_Nd
			a.refl_func_fresnel = on
			a.refl_color = origMtl.Fresnel_Color
			a.refl_gloss = (1-origMtl.BSDF_Roughness/100)
			if origMtl.BSDF_Roughness < 40 then a.refl_weight  = origMtl.Fresnel_Color.value/255 else a.refl_weight = 0
			a.anisotropy = (1+origMtl.BSDF_Anisotropy/10)
			a.anisoangle = origMtl.BSDF_Anisotropy_Angle/360
		)
		
		--segunda capa
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:1
			peso_B = origMtl.Layer_Weight
			b.name = origMtl.Layer_name
		if origMtl.Use_Emitter == on then --solo se tiene en cuenta color+luminancia
		(
			b.self_illum_on = on
			if origMtl.Emitter_color_type == 0 then 
			(
				b.self_illum_color_mode = off
				b.self_illum_color_filter = origMtl.Emitter_RGB_Color
			) 
			else
				(
					b.self_illum_color_mode = on
					b.self_illum_color_kelvin = origMtl.Emitter_Correlated_Color
				)
			if origMtl.Emitter_luminance_type == 0 then
			(
				b.self_illum_int_mode = on
				b.self_illum_int_arbitrary = origMtl.Emitter_Watts/40 --usamos como valor base 40W
			) --mirar las equivalencias para los valores f韘icos con illum_int_mode off
			
		) else
		(
			b.diff_color = origMtl.BSDF_Reflected_Color
			b.diff_color_map = origMtl.BSDF_Reflected_Color_Texture
			b.bump_map_amt = origMtl.BSDF_Bump_Strength/100
			b.bump_map = origMtl.BSDF_Bump_Strength_Texture
			if origMtl.Transparency_Color.value > 0 then 
			(
				b.refr_falloff_on = on
				b.refr_falloff_color_on = on
				b.refr_falloff_dist = origMtl.BSDF_Absorption/100
				b.refr_falloff_color = origMtl.Transparency_Color
				b.refr_weight = origMtl.Transparency_Color.value/255
			)
				
			b.cutout_map = origMtl.BSDF_Transparency_Color_Texture
			b.refr_ior = origMtl.BSDF_Nd
			b.refl_func_fresnel = on
			b.refl_color = origMtl.Fresnel_Color
			b.refl_gloss = (1-origMtl.BSDF_Roughness/100)
			if origMtl.BSDF_Roughness < 40 then b.refl_weight  = origMtl.Fresnel_Color.value/255 else b.refl_weight = 0
			b.anisotropy = (1+origMtl.BSDF_Anisotropy/10)
			b.anisoangle = origMtl.BSDF_Anisotropy_Angle/360
		)
			pesos = peso_A+peso_B
			m.mixAmount = 100-(peso_A*100/pesos)
			format "Converted to %\n" m to:templog
			try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":MaxwellMaterial converted to "+m.name+":Arch___Design__mi")) catch()
			return m
	)
	else
	(
		--vamos s髄o con una capa
		m = Arch___Design__mi ()
		m.name = origMtl.name
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:0
		if origMtl.Use_Emitter == on then --solo se tiene en cuenta color+luminancia
		(
			m.self_illum_on = on
			if origMtl.Emitter_color_type == 0 then 
			(
				m.self_illum_color_mode = off
				m.self_illum_color_filter = origMtl.Emitter_RGB_Color
			) 
			else
				(
					m.self_illum_color_mode = on
					m.self_illum_color_kelvin = origMtl.Emitter_Correlated_Color
				)
			if origMtl.Emitter_luminance_type == 0 then
			(
				m.self_illum_int_mode = on
				m.self_illum_int_arbitrary = origMtl.Emitter_Watts/40 --usamos como valor base 40W
			) --mirar las equivalencias para los valores f韘icos con illum_int_mode off
			
		) else
		(
			m.diff_color = origMtl.BSDF_Reflected_Color
			m.diff_color_map = origMtl.BSDF_Reflected_Color_Texture
			m.bump_map_amt = origMtl.BSDF_Bump_Strength/100
			m.bump_map = origMtl.BSDF_Bump_Strength_Texture
			if origMtl.Transparency_Color.value > 0 then 
			(
				m.refr_falloff_on = on
				m.refr_falloff_color_on = on
				m.refr_falloff_dist = origMtl.BSDF_Absorption/100
				m.refr_falloff_color = origMtl.Transparency_Color
				m.refr_weight = origMtl.Transparency_Color.value/255
			)
				
			m.cutout_map = origMtl.BSDF_Transparency_Color_Texture
			m.refr_ior = origMtl.BSDF_Nd
			m.refl_func_fresnel = on
			m.refl_color = origMtl.Fresnel_Color
			m.refl_gloss = (1-origMtl.BSDF_Roughness/100)
			if origMtl.BSDF_Roughness < 40 then m.refl_weight  = origMtl.Fresnel_Color.value/255 else m.refl_weight = 0
			m.anisotropy = (1+origMtl.BSDF_Anisotropy/10)
			m.anisoangle = origMtl.BSDF_Anisotropy_Angle/360
		)		
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":MaxwellMaterial converted to "+m.name+":Arch___Design__mi")) catch()
		return m
	)
)

fn vraylight2mental origmtl =(
	
	m = Arch___Design__mi ()
	m.name = origmtl.name
	m.self_illum_on = on
	m.self_illum_color_filter = origmtl.color
	m.self_illum_map = ValidaMapaMental origmtl.texmap
	m.diff_color_map = ValidaMapaMental origmtl.texmap
	m.self_illum_int_arbitrary = origmtl.multiplier*5
	m.refl_weight = 0
	m.self_illum_int_mode = off
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayLightMtl converted to "+m.name+":Arch___Design__mi")) catch()
	return m
)


----------------------------------------------------------------
---FUNCIONES PARA CONVERTIR A THEA RENDER---
----------------------------------------------------------------

fn ValidaMapaThea MapaOrig=(
		
	mapa = classof MapaOrig
	--format "mapa:% - clase:%" mapaorig.name mapa
	if (mapa == UndefinedClass) then return undefined
	if (mapa == Bitmap_Thea) then return mapa
	if (mapa == Bitmaptexture) then
	(
		if mapaOrig.filename!=undefined then 
		(
			if ((mapaOrig.apply) and (mapaOrig.cropPlace==0)) then
			(
				mr = rendercrop mapaOrig
				mr.coords = mapaOrig.coords
				return mr
			) else
			(
				mr = Bitmap_Thea()
				mr.filename = mapaOrig.filename
				mr.bitmap.coords = mapaOrig.coords
				return mr
			)
		)
		--print "dentro bitmap"
	)
	if (mapa == RGB_Tint) then
		(
			mr = Bitmap_Thea()
			mr.th_red = mapaorig.red.value
			mr.th_green = mapaorig.green.value
			mr.th_blue = mapaorig.blue.value
			try (return ValidaMapaThea MapaOrig.map1) catch()
		) 
	
	if (mapa == RGB_Multiply) then
		(
			mr = Bitmap_Thea()			
			try (return ValidaMapaThea MapaOrig.map1) catch()
		) 

	if (mapa == Bump__3dsmax) then 
		(
			return ValidaMapaThea MapaOrig.map
		)
	
	if (mapa == Normal_Bump) then (return ValidaMapaThea MapaOrig.normal_map)
		
	if (mapa == Forest_Color) then
		(
			return ValidaMapaThea MapaOrig.mapbase
		)
		
	if (mapa == Color_Correction) then
		(
			if ((classof mapaorig.map==Bitmaptexture) and (mapaOrig.map.filename!=undefined)) then 
			(
				try
				(
					mr = Bitmap_Thea()
					mr.bitmap = mapaOrig.map.bitmap
				) catch (return mr)
					mr.saturation = mapaorig.saturation
				if (mapaorig.lightnessMode==0) then
				(
					mr.brightness = mapaorig.brightness
					mr.contrast = mapaorig.contrast
				) else
				(
					g0=mapaorig.gammaRGB
					case of
					(
						(g0<0.3): mr.gamma=-100
						((g0<=1) and (g0>=0.3)): mr.gamma=(-((g0-0.3)*100/0.7))
						((g0>1) and (g0<=3)): mr.gamma=(g0-1)/2*100
						(g0>3): mr.gamma=100
					)
				)
				case mapaorig.rewireMode of
				(
					1: (mr.saturation=-100)
					2: (mr.complement=on)
				)
				return mr
			)
		)
	
	if (mapa == ColorCorrect) then
		(
			if ((classof mapaorig.src_tex==Bitmaptexture) and (mapaOrig.src_tex.filename!=undefined)) then 
			(
				mr = Bitmap_Thea()
				try	(mr.bitmap = mapaOrig.src_tex.bitmap) catch(return mr)
				mr.saturation = mapaorig.saturation
				if (mapaorig.pre_on==on) then
				(
					mr.brightness = mapaorig.brightness
					mr.contrast = mapaorig.contrast-100
					if (mapaorig.pre_mono==on) then mr.saturation=-100
					if (mapaorig.pre_invert==on) then mr.inverted=on
				) 
				if (mapaorig.rgba_on==on) then
				(
					mr.th_red=mapaorig.red_off
					mr.th_green=mapaorig.green_off
					mr.th_blue=mapaorig.blue_off
				)
				
				return mr
			)
		)
	
	if procedural then 
	(
		return salvaproc MapaOrig
	)
	else return undefined
		
)

fn salvaprocthea MapaOrig = (
	rdn = random 1 9999 as string
	nomproc = MapaOrig.name
	rbm = renderMap MapaOrig size:[anchoproc,altoproc]
	rbm.filename = dirproc + "\\" + nomproc + rdn + extension
	format "Generate map % ...\n" rbm.filename to:templog
	save rbm
	nuevoproc = Bitmap_Thea()
	nuevoproc.filename = rbm.filename
	nuevoproc.name = nomproc
	close rbm
	return nuevoproc
)

fn MWtex2thea origtex=(
	tex=bitmap_thea()
	tex.bitmap.filename = origtex.filename 
	tex.bitmap.coords.U_Tiling = origtex.TileX
	tex.bitmap.coords.V_Tiling = origtex.TileY
	tex.bitmap.coords.U_Offset = origtex.OffsetX
	tex.bitmap.coords.V_Offset = origtex.OffsetY
	tex.bitmap.coords.mapchannel = origtex.channel
	tex.alpha_channel = origtex.AlphaOnly
	tex.saturation = origtex.saturation
	tex.contrast = origtex.contrast
	tex.brightness = origtex.brightness
	tex.clamp_min = (origtex.RGBClampMin/2.55)
	tex.clamp_max = (origtex.RGBClampMax/2.55)
	tex.inverted = origtex.invert
	return tex
)

fn std2thea origMtl =(
	
	s=Thea_Material()
	s.name=origMtl.name
	
	s.materiallist[1].diffuse=origMtl.diffuse
	if (origmtl.diffuseMap != undefined AND origmtl.diffuseMapEnable) then s.materiallist[1].diffuse_tex = ValidaMapaThea origmtl.diffuseMap
	if (origmtl.bumpMap != undefined AND origmtl.bumpMapEnable) then s.materiallist[1].bump_tex = ValidaMapaThea origmtl.bumpMap
	s.materiallist[1].bump = origMtl.bumpMapAmount
	
	if (origmtl.reflectionMap != undefined AND origmtl.reflectionMapEnable) then s.materiallist[1].reflectance_tex = ValidaMapaThea origmtl.reflectionMap
	val= origMtl.specularLevel/2.55
	s.materiallist[1].reflectance=color val val val
	s.materiallist[1].roughness = (100-origMtl.glossiness)/2.55
	
	if (origMtl.opacityMap != undefined AND origmtl.opacityMapEnable) then
		(
			s.clip_enabled=on
			s.clip_tex = ValidaMapaThea origmtl.opacityMap
		)
		
	format "Converted to %\n" s to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Standardmaterial converted to "+s.name+":Thea_Material")
	windows.processPostedMessages()) catch()
	return s
)

fn vray2thea origMtl = (
	
	s= Thea_Material()
	s.name = origMtl.name
	
	if origMtl.Refraction.value > 15 then
	(
		if (roll_Thea.chk_glass.checked and (origMtl.Refraction.value > 190) and (origMtl.reflection_glossiness > 0.9)) then
		(
			s.materiallist[1]=Thea_ThinFilm_Layer()
			s.materiallist[1].name=origMtl.name+"_glass"
			s.materiallist[1].transmittance = color_gamma origMtl.Refraction displaygamma 1.0
			if (origmtl.texmap_refraction != undefined AND origmtl.texmap_refraction_on) then s.materiallist[1].transmittance_tex = ValidaMapaThea origmtl.texmap_refraction
			s.materiallist[1].thin_bump = origMtl.texmap_bump_multiplier
			if (origmtl.texmap_bump != undefined AND origmtl.texmap_bump_on) then 
			(
				if ((classof origmtl.texmap_bump) != Normal_Bump) then s.materiallist[1].bump_tex = ValidaMapaThea origmtl.texmap_bump else
				(
					s.materiallist[1].thin_normal=true
					ValidaMapaThea origmtl.texmap_bump
				)
			)
		)
		else
		(
			s.materiallist[1]=Thea_Glossy_Layer()
			s.materiallist[1].name=origMtl.name+"_glossy"
			s.materiallist[1].reflectance = color_gamma origMtl.Diffuse displaygamma 1.0 
			s.materiallist[1].reflectance.value = origMtl.Reflection.value
			s.materiallist[1].reflectance90 = color 255 255 255
			if (origmtl.texmap_diffuse != undefined AND origmtl.texmap_diffuse_on) then 
			(
				if ((classof origmtl.texmap_reflection) == falloff) then 
				(
					s.materiallist[1].reflectance=origmtl.texmap_reflection.color2 
					s.materiallist[1].reflectance_tex=undefined
				) else s.materiallist[1].reflectance_tex = ValidaMapaThea origmtl.texmap_reflection
			)
						
			s.materiallist[1].transmittance = color_gamma origMtl.Refraction displaygamma 1.0
			if (origmtl.texmap_refraction != undefined AND origmtl.texmap_refraction_on) then s.materiallist[1].transmittance_tex = ValidaMapaThea origmtl.texmap_refraction
			
			s.materiallist[1].absorption_col = color_gamma origMtl.refraction_fogColor displaygamma 1.0 
			s.materiallist[1].absorption = origMtl.refraction_fogMult
			s.materiallist[1].roughness = fn_glossy_thea origMtl.reflection_glossiness
			s.materiallist[1].roughnessTr = fn_glossy_thea origMtl.refraction_glossiness
			
			s.materiallist[1].bump = origMtl.texmap_bump_multiplier
			if (origmtl.texmap_bump != undefined AND origmtl.texmap_bump_on) then 
			(
				if ((classof origmtl.texmap_bump) != Normal_Bump) then s.materiallist[1].bump_tex = ValidaMapaThea origmtl.texmap_bump else
				(
					s.materiallist[1].normal=true
					ValidaMapaThea origmtl.texmap_bump
				)
			)
		)
	)
	else
	(
		s.materiallist[1] = Thea_Basic_Layer()
		s.materiallist[1].name = origMtl.name+"_basic"
		s.materiallist[1].Diffuse = color_gamma origMtl.Diffuse displaygamma 1.0
		if (origmtl.texmap_diffuse != undefined AND origmtl.texmap_diffuse_on) then s.materiallist[1].diffuse_tex = ValidaMapaThea origmtl.texmap_diffuse
		
		s.materiallist[1].reflectance = origMtl.reflection
		if (origmtl.texmap_reflection != undefined AND origmtl.texmap_reflection_on) then 
		(
			if ((classof origmtl.texmap_reflection) == falloff) then 
			(
				s.materiallist[1].reflectance=origmtl.texmap_reflection.color2 
				s.materiallist[1].reflectance_tex=undefined
			) else s.materiallist[1].reflectance_tex = ValidaMapaThea origmtl.texmap_reflection
		)
		
		s.materiallist[1].roughness = fn_glossy_thea origMtl.reflection_glossiness
		if s.materiallist[1].reflectance.value>0 then s.materiallist[1].reflectance90 = color 255 255 255
		
		if origMtl.translucency_on!=0 then 
		(
			s.materiallist[1].translucent = origMtl.translucency_color
			if (origmtl.texmap_translucent != undefined) then s.materiallist[1].translucent_tex = ValidaMapaThea origmtl.texmap_translucent
		)	
		s.materiallist[1].bump = origMtl.texmap_bump_multiplier
		if (origmtl.texmap_bump != undefined AND origmtl.texmap_bump_on) then 
		(
			if ((classof origmtl.texmap_bump) != Normal_Bump) then s.materiallist[1].bump_tex = ValidaMapaThea origmtl.texmap_bump else
			(
				s.materiallist[1].normal=true
				ValidaMapaThea origmtl.texmap_bump
			)
		)
	)	
	if (origMtl.reflection_fresnel == on) then s.materiallist[1].ior = origMtl.reflection_ior else	s.materiallist[1].ior = origMtl.refraction_ior	
	
	
	if classof s.materiallist[1]!=Thea_ThinFilm_Layer then
	(
		s.materiallist[1].anisotropy = abs(origMtl.anisotropy)*100
		if (origmtl.texmap_anisotropy != undefined AND origmtl.texmap_anisotropy_on) then s.materiallist[1].anisotropy_tex = ValidaMapaThea origmtl.texmap_anisotropy
		
		s.materiallist[1].aniso_rot = int(abs(mod origMtl.anisotropy_rotation 360))
		if (origmtl.texmap_anisotropy_rotation != undefined AND origmtl.texmap_anisotropy_rotation_on) then s.materiallist[1].aniso_rot_tex = ValidaMapaThea origmtl.texmap_anisotropy_rotation
	)
	if (origMtl.texmap_opacity != undefined AND origmtl.texmap_opacity_on) then
		(
			s.clip_enabled=on
			s.clip_tex = ValidaMapaThea origmtl.texmap_opacity
		)
		
	format "Converted to %\n" s to:templog	
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+s.name+":Thea_Material")
	windows.processPostedMessages()) catch()
	return s
)

fn vraylightMtl2thea origMtl =(
	
	s = Thea_Material()
	s.name = origmtl.name
	s.materiallist[1]=undefined
	s.emit_enabled = on
	s.emit_color = origmtl.color
	if (origmtl.texmap != undefined AND origmtl.texmap_on) then s.emit_tex = ValidaMapaThea origmtl.texmap
	
	if (origmtl.opacity_texmap != undefined AND origmtl.opacity_texmap_on) then
	(
		s.clip_enabled = on
		s.clip_tex = ValidaMapaThea origmtl.opacity_texmap
	)
	
	format "Converted to %\n" s to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayLightMtl converted to "+s.name+":Thea_Material")) catch()
	return s
)

fn vrayblendMtl2Thea origMtl =(
	s=Thea_Material()
	s.name = origMtl.name
	try
	(
		if origMtl.baseMtl!=undefined then
		(
			s = vray2thea origMtl.baseMtl
			if origMtl.coatMtl[1]!=undefined then
			(
				t= vray2thea origMtl.coatMtl[1]
				s.materiallist[2]=t.mat1
				if origMtl.texmap_blend[1]!=undefined then
				(
					s.maskList[2]=ValidaMapaThea origMtl.texmap_blend[1] 
					s.amountList[2]=(origMtl.texmap_blend_multiplier[1] as integer)
				) else
				(
					val=(2*(origMtl.blend[1].value/2.55) as integer)
					if val>100 then
					(
						offset=10000/val
						s.amountList[1]=offset as integer
						s.amountList[2]=100
					) else s.amountList[2]=val
				)
			)
		)
	) catch()
	return s
)

fn Mental2thea origMtl = (
	s= Thea_Material()
	s.name = origMtl.name
	if origMtl.refr_weight*origMtl.refr_color.value > 0.05 then
	(
		if origMtl.opts_1sided == on then
		(
			s.materiallist[1]=Thea_ThinFilm_Layer()
			s.materiallist[1].transmittance = color_gamma origMtl.refr_color displaygamma 1.0 
			s.materiallist[1].transmittance.value=origmtl.refr_weight*255
			
			s.materiallist[1].thin_bump = origMtl.bump_map_amt*100
			if (origmtl.bump_map != undefined AND origmtl.bump_map_on) then s.materiallist[1].bump_tex = ValidaMapaThea origmtl.bump_map
			
		) else
		(
			s.materiallist[1]=Thea_Glossy_Layer()
			s.materiallist[1].name=origMtl.name+"_glossy"
			s.materiallist[1].reflectance = color_gamma origMtl.diff_color displaygamma 1.0
			s.materiallist[1].reflectance.value = origMtl.diff_color.value*255
			if (origmtl.diff_color_map != undefined AND origmtl.diff_color_map_on) then s.materiallist[1].reflectance_tex = ValidaMapaThea origmtl.diff_color_map
						
			s.materiallist[1].transmittance = origMtl.refr_color
			s.materiallist[1].transmittance.value=origmtl.refr_weight*255
			
			if (origmtl.refr_color_map != undefined AND origmtl.refr_color_map_on) then s.materiallist[1].transmittance_tex = ValidaMapaThea origmtl.refr_color_map
			
			s.materiallist[1].absorption_col = color_gamma origMtl.refr_falloff_color displaygamma 1.0
			s.materiallist[1].absorption = origMtl.refr_falloff_dist*100
			s.materiallist[1].roughness = (1-origMtl.refl_gloss)*100.0
			s.materiallist[1].roughnessTr = (1-origMtl.refr_gloss)*100.0
			
		)
	)
	else
	(
		if origMtl.refl_metal then 
		(
			s.materiallist[1]=Thea_Glossy_Layer()
			s.materiallist[1].name=origMtl.name+"_glossy"
			s.materiallist[1].reflectance = color_gamma origMtl.diff_color displaygamma 1.0
			s.materiallist[1].reflectance.value = origMtl.refl_weight*255
			if (origmtl.diff_color_map != undefined AND origmtl.diff_color_map_on) then s.materiallist[1].reflectance_tex = ValidaMapaThea origmtl.diff_color_map
			s.materiallist[1].roughness = (1-origMtl.refl_gloss)*100.0
		)
		else
		(
			s.materiallist[1] = Thea_Basic_Layer()
			s.materiallist[1].name = origMtl.name+"_basic"
			s.materiallist[1].Diffuse = color_gamma origMtl.diff_color displaygamma 1.0
			if (origmtl.diff_color_map != undefined AND origmtl.diff_color_map_on) then s.materiallist[1].diffuse_tex = ValidaMapaThea origmtl.diff_color_map
			
			s.materiallist[1].reflectance = origMtl.refl_color*origMtl.refl_weight
			if (origmtl.refl_color_map != undefined AND origmtl.refl_color_map_on) then s.materiallist[1].reflectance_tex = ValidaMapaThea origmtl.refl_color_map
			s.materiallist[1].roughness = (1-origMtl.refl_gloss)*100.0
			
			s.materiallist[1].translucent = origMtl.refr_color*origMtl.refr_weight
			--s.mat1.translucent.value = origMtl.refr_weight*255
			if (origmtl.refr_color_map != undefined AND origmtl.refr_color_map_on) then s.materiallist[1].translucent_tex = ValidaMapaThea origmtl.refr_color_map
		)		
	)
	
	s.materiallist[1].ior = origMtl.refr_ior
	
	try(
	s.materiallist[1].bump = origMtl.bump_map_amt*100
	if (origmtl.bump_map != undefined AND origmtl.bump_map_on) then 
	(
		if ((classof origmtl.bump_map) != Normal_Bump) then s.materialList[1].bump_tex = ValidaMapaThea origmtl.bump_map else
		(
			s.materiallist[1].normal=true
			s.materialList[1].bump_tex=ValidaMapaThea origmtl.bump_map
		)
	)
	
	s.materiallist[1].anisotropy = (1-origMtl.anisotropy)*100
	if (origmtl.anisotropy_map != undefined AND origmtl.anisotropy_map_on) then s.materiallist[1].anisotropy_tex = ValidaMapaThea origmtl.anisotropy_map
	
	s.materiallist[1].aniso_rot = int(origMtl.anisoangle*360)
	if (origmtl.anisoangle_map != undefined AND origmtl.anisoangle_map_on) then s.materiallist[1].aniso_rot_tex = ValidaMapaThea origmtl.anisoangle_map
	) catch()
	
	if (origMtl.cutout_map != undefined AND origmtl.cutout_map_on) then
		(
			s.clip_enabled=on
			s.clip_tex = ValidaMapaThea origmtl.cutout_map
		)
		
	if origMtl.self_illum_on then
	(
		s.emit_enabled=on
		if (origMtl.self_illum_color_mode == on) then s.emit_color = fn_kelvin2rgb origMtl.self_illum_color_kelvin else s.emit_color = origMtl.self_illum_color_filter
		if (origmtl.self_illum_map != undefined AND origmtl.self_illum_map_on) then s.emit_tex = ValidaMapaThea origmtl.self_illum_map
		if origMtl.self_illum_int_mode then s.power = origMtl.self_illum_int_arbitrary*1500 else s.power = origMtl.self_illum_int_physical
		s.unit = 6  --cd/m2
	)
		
	format "Converted to %\n" s to:templog	
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+s.name+":Thea_Material")
	windows.processPostedMessages()) catch()
	return s
)

fn CarMental2thea origMtl =(
	
	s= Thea_Material()
	s.name = origMtl.name
	s.materiallist[1].diffuse = origMtl.edge_color
	s.materiallist[1].reflectance = origMtl.base_color
	s.materiallist[1].ior = 5.0
	s.materiallist[1].roughness = 35
	s.materialList[5] = Thea_Coating_Layer()
	s.materialList[5].reflectance = (color 255 255 255)
	s.materialList[5].roughness = 0
	
	format "Converted to %\n" s to:templog		
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Car_Paint_Material__mi converted to "+s.name+":Thea_Material")) catch()
	return s
	
)

fn MW2thea origMtl = (
	return origMtl
)

fn MW2thea_v2 origMtl=(
	
	s=Thea_Material()
	s.name = origMtl.name
	
	local num_stack=0
	local num_base=0
	local stacked=#()
	local base=#()
	local numcapas=origMtl.Layers.count
	local submat = #(s.materiallist[1],s.materiallist[2],s.materiallist[3],s.materiallist[5],s.materiallist[6],s.materiallist[7])
	local submask = #(s.maskList[1],s.maskList[2],s.maskList[3],s.maskList[5],s.maskList[6],s.maskList[7])
	local subpercent = #(s.amountList[1],s.amountList[2],s.amountList[3],s.amountList[5],s.amountList[6],s.amountList[7])
	local abbe = origMtl.Dispersion
	print numcapas
	for i=1 to numcapas do ---------------------------------------------------------------------------------------------------  recorremos las capas
	(
		if ((origMtl.Layers[i].Emitter!=undefined) and (origMtl.Layers[i].Emitter.enabled == on)) then --emitters
		(
			s.emit_enabled=on
			tipo = origMtl.Layers[i].Emitter.type
			case tipo of
			(
				0: (
						if origMtl.Layers[i].Emitter.ColorType==0 then
						(
							s.emit_color_scale=1
							s.emit_color = origMtl.Layers[i].Emitter.rgb
						)
						else
						(
							s.emit_color_scale=2
							s.emit_kelvin = (origMtl.Layers[i].Emitter.CorrelatedColor as integer)
						)
						tipolum = origMtl.Layers[i].Emitter.LuminanceType
						case tipolum of
						(
							0: (
									s.unit = 1
									s.power = origMtl.Layers[i].Emitter.Watts
									s.efficacy = origMtl.Layers[i].Emitter.efficacy
							)
							1: (
									s.unit = 4
									s.power = origMtl.Layers[i].Emitter.luminance
							)
							2: (
									s.use_ies=on
									s.ies_file = origMtl.Layers[i].Emitter.IESFilename
							)
						)
					)
				1: (
						s.emit_color_scale=2
						s.emit_kelvin = (origMtl.Layers[i].Emitter.CorrelatedColor as integer)
				)
				2: (
						if origMtl.Layers[1].Emitter.MXIHDRTexture!=undefined then
						(
							b=Bitmap_Thea()
							b.bitmap.filename = origMtl.Layers[1].Emitter.MXIHDRTexture.FileName
							s.emit_tex = b
						)
				)
			)
			
		) --fin emitter
		
		if ((numcapas==1) and (origMtl.Layers[1].mask!=undefined) and (origMtl.Layers[1].mask.filename!=undefined)) then
		(
			s.clip_enabled = on
			s.clip_tex = MWtex2thea origMtl.Layers[1].mask
		)
		
		if ((origMtl.Layers[i].BlendMode==0) and (num_base<4)) then
		(
			if (origMtl.Layers[i].bsdfs.count==1) then
			(
				if ((origMtl.Layers[i].Mask!=undefined) and (origMtl.Layers[i].Mask.filename!=undefined)) then submask[i] = MWtex2thea origMtl.Layers[i].Mask
				--subpercent[i]=origMtl.Layers[i].opacity
			)
			for j=1 to origMtl.Layers[i].bsdfs.count do 
			(
				if (num_base<4) then
				(
					append base origMtl.Layers[i].bsdfs[j]
					a = base.count
					if (subpercent[a]==100) then subpercent[a]=base[a].SurfaceWeight
					if (submask[a]==undefined) then try (submask[a] = MWtex2thea base[a].SurfaceWeightTexture) catch()
					num_base+=1
				)
			)
					
		)
		
		else if ((origMtl.Layers[i].BlendMode==1) and (num_stack<4)) then
		(
			if (origMtl.Layers[i].bsdfs.count==1)  then
			(
				k = (i+3)
				if ((origMtl.Layers[i].Mask!=undefined) and (origMtl.Layers[i].Mask.filename!=undefined)) then submask[k] = MWtex2thea origMtl.Layers[i].Mask
				--subpercent[k]=origMtl.Layers[i].opacity
				--format "subp %: %\n" k subpercent[k]
			)
			for j=1 to origMtl.Layers[i].bsdfs.count do
			(
				
				if (num_stack<4) then
				(
					append stacked origMtl.Layers[i].bsdfs[j]
					a = stacked.count
					if (subpercent[(a+3)]==100) then subpercent[(a+3)]=stacked[a].SurfaceWeight
					if (subpercent[(a+3)]==100) then subpercent[(a+3)]=(100/origMtl.Layers.count)
					--format "subp %: % total: %\n" (a+3) subpercent[(a+3)] subpercent
					if (submask[(a+3)]==undefined) then try (submask[(a+3)] = MWtex2thea stacked[a].SurfaceWeightTexture) catch()
					num_stack+=1
				)
			)
			
		)
	)
	
	for i=1 to base.count do
	(
		--decidir si basic o glossy
		if ((base[i].TransparencyColor!=(color 0 0 0) or (base[i].TransparencyColorTexture!=undefined) or (base[i].Nd>3))) then --usamos glossy
		(		
			submat[i] = Thea_Glossy_Layer()
			submat[i].name = base[i].name
			if ((base[i].ReflectedColorTexture!=undefined) and (base[i].ReflectedColorTexture.filename!=undefined)) then
			(
				submat[i].reflectance_tex=MWtex2thea base[i].ReflectedColorTexture --funcion para las texturas			
			)
			else submat[i].reflectance = base[i].ReflectedColor
			if ((base[i].TransparencyColorTexture!=undefined) and (base[i].TransparencyColorTexture.filename!=undefined)) then
			(
				submat[i].transmittance_tex=MWtex2thea base[i].TransparencyColorTexture --funcion para las texturas		
				submat[i].absorption_col = base[i].TransparencyColor				
			)
			else
			(
				submat[i].transmittance = base[i].TransparencyColor
				submat[i].absorption_col = base[i].TransparencyColor
			)
			submat[i].absorption= base[i].absorption
			submat[i].IOR = base[i].Nd
			submat[i].extinction = base[i].k
			if abbe then
			(
				submat[i].abbe_on = on
				submat[i].abbe = base[i].abbe
			)
			-- 		if base[i].UseIORFile == on then 
			-- 		(
			-- 			submat[i].iorfile_on = on
			-- 			submat[i].IORfilename = base[i].IORFilename
			-- 		)
			if ((base[i].RoughnessTexture!=undefined) and (base[i].RoughnessTexture.filename!=undefined)) then
			(
				submat[i].roughness_tex=MWtex2thea base[i].RoughnessTexture --funcion para las texturas			
			)
			submat[i].roughness = base[i].roughness
			
			if ((base[i].AnisotropyTexture!=undefined) and (base[i].AnisotropyTexture.filename!=undefined)) then
			(
				submat[i].anisotropy_tex=MWtex2thea base[i].AnisotropyTexture --funcion para las texturas			
			)
			submat[i].anisotropy = base[i].anisotropy
			
			if ((base[i].AnisotropyAngleTexture!=undefined) and (base[i].AnisotropyAngleTexture.filename!=undefined)) then
			(
				submat[i].aniso_rot_tex=MWtex2thea base[i].AnisotropyAngleTexture --funcion para las texturas			
			)
			submat[i].aniso_rot = base[i].AnisotropyAngle
			
			if ((base[i].BumpStrengthTexture!=undefined) and (base[i].BumpStrengthTexture.filename!=undefined)) then
			(
				submat[i].bump_tex=MWtex2thea base[i].BumpStrengthTexture --funcion para las texturas	
				if base[i].BumpAsNormalmap==on then submat[i].normal=on
			)
			submat[i].bump = base[i].BumpStrength
		)
		else --usamos basic
		(
			submat[i] = Thea_Basic_Layer()
			submat[i].name = base[i].name
			if ((base[i].ReflectedColorTexture!=undefined) and (base[i].ReflectedColorTexture.filename!=undefined)) then
			(
				submat[i].diffuse_tex=MWtex2thea base[i].ReflectedColorTexture --funcion para las texturas		
				if base[i].roughness!=100 then submat[i].reflectance = base[i].ReflectedColor
			)
			else
			(
				if base[i].roughness!=100 then submat[i].reflectance = base[i].ReflectedColor
				submat[i].Diffuse = base[i].ReflectedColor
			)
			if ((base[i].UseThickness=on) and (base[i].ThicknessTexture!=undefined) and (base[i].ThicknessTexture.filename!=undefined)) then
			(
				submat[i].translucent_tex = bitmap_thea()
				submat[i].translucent_tex.bitmap.filename = MWtex2thea base[i].ThicknessTexture.filename		
			)
			submat[i].absorption_col = base[i].TransparencyColor
			submat[i].absorption_val= base[i].absorption
			submat[i].IOR = base[i].Nd
			submat[i].extinction = base[i].k
			
			if ((base[i].RoughnessTexture!=undefined) and (base[i].RoughnessTexture.filename!=undefined)) then
			(
				submat[i].roughness_tex=MWtex2thea base[i].RoughnessTexture --funcion para las texturas			
			)
			submat[i].roughness = base[i].roughness
			
			if ((base[i].AnisotropyTexture!=undefined) and (base[i].AnisotropyTexture.filename!=undefined)) then
			(
				submat[i].anisotropy_tex=MWtex2thea base[i].AnisotropyTexture --funcion para las texturas			
			)
			submat[i].anisotropy = base[i].anisotropy
			
			if ((base[i].AnisotropyAngleTexture!=undefined) and (base[i].AnisotropyAngleTexture.filename!=undefined)) then
			(
				submat[i].aniso_rot_tex=MWtex2thea base[i].AnisotropyAngleTexture --funcion para las texturas			
			)
			submat[i].aniso_rot = base[i].AnisotropyAngle
			
			if ((base[i].BumpStrengthTexture!=undefined) and (base[i].BumpStrengthTexture.filename!=undefined)) then
			(
				submat[i].bump_tex=MWtex2thea base[i].BumpStrengthTexture --funcion para las texturas	
				if base[i].BumpAsNormalmap==on then submat[i].normal=on
			)
			submat[i].bump = base[i].BumpStrength
		)
	)

	for i=1 to stacked.count do
	(
		--decidir si basic o glossy
		if ((stacked[i].TransparencyColor!=(color 0 0 0) or (stacked[i].TransparencyColorTexture!=undefined) or (stacked[i].Nd>3))) then --usamos glossy
		(
			k=(i+3)
			submat[k] = Thea_Glossy_Layer()
			submat[k].name = stacked[i].name
			if ((stacked[i].ReflectedColorTexture!=undefined) and (stacked[i].ReflectedColorTexture.filename!=undefined)) then
			(
				submat[k].reflectance_tex=MWtex2thea stacked[i].ReflectedColorTexture --funcion para las texturas			
			)
			else submat[k].reflectance = stacked[i].ReflectedColor
			if ((stacked[i].TransparencyColorTexture!=undefined) and (stacked[i].TransparencyColorTexture.filename!=undefined)) then
			(
				submat[k].transmittance_tex=MWtex2thea stacked[i].TransparencyColorTexture --funcion para las texturas		
				submat[k].absorption_col = stacked[i].TransparencyColor				
			)
			else
			(
				submat[k].transmittance = stacked[i].TransparencyColor
				submat[k].absorption_col = stacked[i].TransparencyColor
			)
			submat[k].absorption= stacked[i].absorption
			submat[k].IOR = stacked[i].Nd
			submat[k].extinction = stacked[i].k
			if abbe then
			(
				submat[k].abbe_on = on
				submat[k].abbe = stacked[i].abbe
			)
	-- 		if base[i].UseIORFile == on then 
	-- 		(
	-- 			submat[k].iorfile_on = on
	-- 			submat[k].IORfilename = stacked[i].IORFilename
	-- 		)
			if ((stacked[i].RoughnessTexture!=undefined) and (stacked[i].RoughnessTexture.filename!=undefined)) then
			(
				submat[k].roughness_tex=MWtex2thea stacked[i].RoughnessTexture --funcion para las texturas			
			)
			submat[k].roughness = stacked[i].roughness
			
			if ((stacked[i].AnisotropyTexture!=undefined) and (stacked[i].AnisotropyTexture.filename!=undefined)) then
			(
				submat[k].anisotropy_tex=MWtex2thea stacked[i].AnisotropyTexture --funcion para las texturas			
			)
			submat[k].anisotropy = stacked[i].anisotropy
			
			if ((stacked[i].AnisotropyAngleTexture!=undefined) and (stacked[i].AnisotropyAngleTexture.filename!=undefined)) then
			(
				submat[k].aniso_rot_tex=MWtex2thea stacked[i].AnisotropyAngleTexture --funcion para las texturas			
			)
			submat[k].aniso_rot = stacked[i].AnisotropyAngle
			
			if ((stacked[i].BumpStrengthTexture!=undefined) and (stacked[i].BumpStrengthTexture.filename!=undefined)) then
			(
				submat[k].bump_tex=MWtex2thea stacked[i].BumpStrengthTexture --funcion para las texturas	
				if stacked[i].BumpAsNormalmap==on then submat[k].normal=on
			)
			submat[k].bump = stacked[i].BumpStrength
		)
		else --usamos basic
		(
			k=(i+3)
			submat[k] = Thea_Basic_Layer()
			submat[k].name = stacked[i].name
			if ((stacked[i].ReflectedColorTexture!=undefined) and (stacked[i].ReflectedColorTexture.filename!=undefined)) then
			(
				submat[k].diffuse_tex=MWtex2thea stacked[i].ReflectedColorTexture --funcion para las texturas			
				submat[k].reflectance = stacked[i].ReflectedColor
			)
			else
			(
				submat[k].reflectance = stacked[i].ReflectedColor
				submat[k].Diffuse = stacked[i].ReflectedColor
			)
			if ((stacked[i].UseThickness=on) and (stacked[i].ThicknessTexture!=undefined) and (stacked[i].ThicknessTexture.filename!=undefined)) then
			(
				submat[k].translucent_tex = bitmap_thea()
				submat[k].translucent_tex.bitmap.filename = MWtex2thea stacked[i].ThicknessTexture.filename		
			)
			submat[k].absorption_col = stacked[i].TransparencyColor
			submat[k].absorption_val= stacked[i].absorption
			submat[k].IOR = stacked[i].Nd
			submat[k].extinction = stacked[i].k
			
			if ((stacked[i].RoughnessTexture!=undefined) and (stacked[i].RoughnessTexture.filename!=undefined)) then
			(
				submat[k].roughness_tex=MWtex2thea stacked[i].RoughnessTexture --funcion para las texturas			
			)
			submat[k].roughness = stacked[i].roughness
			
			if ((stacked[i].AnisotropyTexture!=undefined) and (stacked[i].AnisotropyTexture.filename!=undefined)) then
			(
				submat[k].anisotropy_tex=MWtex2thea stacked[i].AnisotropyTexture --funcion para las texturas			
			)
			submat[k].anisotropy = stacked[i].anisotropy
			
			if ((stacked[i].AnisotropyAngleTexture!=undefined) and (stacked[i].AnisotropyAngleTexture.filename!=undefined)) then
			(
				submat[k].aniso_rot_tex=MWtex2thea stacked[i].AnisotropyAngleTexture --funcion para las texturas			
			)
			submat[k].aniso_rot = stacked[i].AnisotropyAngle
			
			if ((stacked[i].BumpStrengthTexture!=undefined) and (stacked[i].BumpStrengthTexture.filename!=undefined)) then
			(
				submat[k].bump_tex=MWtex2thea stacked[i].BumpStrengthTexture --funcion para las texturas	
				if stacked[i].BumpAsNormalmap==on then submat[i].normal=on
			)
			submat[k].bump = stacked[i].BumpStrength
		)
	)
	
	--format "base: %\n" base
	--format "stacked: %\n" stacked
	--format "percent: %\n" subpercent
	--format "submask: %\n" submask
	s.materiallist[1] = submat[1]
	s.materiallist[2] = submat[2]
	s.materiallist[3] = submat[3]
	s.materiallist[5] = submat[4]
	s.materiallist[6] = submat[5]
	s.materiallist[7] = submat[6]
	s.maskList[1] = submask[1]
	s.maskList[2] = submask[2]
	s.maskList[3] = submask[3]
	s.maskList[5] = submask[4]
	s.maskList[6] = submask[5]
	s.maskList[7] = submask[6]
	s.amountList[1] = subpercent[1]
	s.amountList[2] = subpercent[2]
	s.amountList[3] = subpercent[3]
	s.amountList[5] = subpercent[4]
	s.amountList[6] = subpercent[5]
	s.amountList[7] = subpercent[6]
	
	format "Converted to %\n" s to:templog	
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Maxwell_Material converted to "+s.name+":Thea_Material")) catch()
	return s
)


fn convertTheaLayer origLayer=(
	case (classof origLayer) of
	(
		(Thea_Basic): (
			l= Thea_Basic_Layer()
			l.Diffuse=origLayer.Diffuse
			l.diffuse_tex=origLayer.diffuse_tex
			l.reflectance=origLayer.reflectance
			l.reflectance_tex=origLayer.reflectance_tex
			l.Translucent=origLayer.Translucent
			l.translucent_tex=origLayer.translucent_tex
			l.absorption_val=origLayer.absorption_val
			l.absorption_col=origLayer.absorption_col
			l.IOR=origLayer.IOR
			l.extinction=origLayer.extinction
			l.trace_refl=origLayer.trace_refl
			l.sigma=origLayer.sigma
			l.sigma_tex=origLayer.sigma_tex
			l.roughness=origLayer.roughness
			l.roughness_tex=origLayer.roughness_tex
			l.anisotropy=origLayer.anisotropy
			l.anisotropy_tex=origLayer.anisotropy_tex
			l.aniso_rot=origLayer.aniso_rot
			l.aniso_rot_tex=origLayer.aniso_rot_tex
			l.bump=origLayer.bump
			l.bump_tex=origLayer.bump_tex
			l.normal=origLayer.normal
			return l
		)
		default:return origLayer
	)
)

fn theaOld2theaNew m=(
	s=Thea_Material()
	s.name=m.name
	s.materialList[1]=convertTheaLayer m.mat1
	s.materialList[2]=m.mat2
	s.materialList[3]=m.mat3
	s.materialList[5]=m.mat4
	s.materialList[6]=m.mat5
	s.materialList[7]=m.mat6
	s.maskList[1]=m.mask1
	s.maskList[2]=m.mask2
	s.maskList[3]=m.mask3
	s.maskList[5]=m.mask4
	s.maskList[6]=m.mask5
	s.maskList[7]=m.mask6
	s.amountList[1]=m.Percent1
	s.amountList[2]=m.Percent2
	s.amountList[3]=m.Percent3
	s.amountList[5]=m.Percent4
	s.amountList[6]=m.Percent5
	s.amountList[7]=m.Percent6
	s.twoSided=m.twoSided
	s.shadow_only=m.shadow_only
	s.repaintable=m.repaintable
	s.dirt=m.dirt
	s.dirt_amount=m.dirt_amount
	s.dirt_tex=m.dirt_tex
	s.perc_level=m.perc_level
	s.minblur=m.minblur-1
	s.maxblur=m.maxblur-1
	s.tracingdepth=m.tracingdepth-1
	if m.bitm_preview==undefined then s.bitm_preview="" else s.bitm_preview=m.bitm_preview
	--s.use_file=m.use_file
	--s.filemat=m.filemat
	s.mtlroom=m.mtlroom
	s.clip_enabled=m.clip_enabled
	s.clip_tex=m.clip_tex
	s.clip_th=m.clip_th
	s.soft=m.soft
	s.disp_enabled=m.disp_enabled
	s.disp_tex=m.disp_tex
	s.disp_subdiv=m.disp_subdiv
	s.disp_micro=m.disp_micro
	s.disp_height=m.disp_height
	s.disp_center=m.disp_center
	s.disp_bounds=m.disp_bounds
	s.disp_smooth=m.disp_smooth
	s.emit_enabled=m.emit_enabled
	s.emit_tex=m.emit_tex
	s.emit_color=m.emit_color
	s.emit_kelvin=m.emit_kelvin
	s.emit_color_scale=m.emit_color_scale-1
	s.use_ies=m.use_ies
	if m.ies_file==undefined then s.ies_file="" else s.ies_file=m.ies_file
	s.ies_multiplier=m.ies_multiplier
	s.power=m.power
	s.efficacy=m.efficacy
	s.unit=m.unit-1
	s.accuracy=m.accuracy
	s.minrays=m.minrays
	s.maxrays=m.maxrays
	s.global_photons=m.global_photons
	s.caustic_photons=m.caustic_photons
	s.medium_enabled=m.medium_enabled
	s.abs_color_tex=m.abs_color_tex
	s.abs_color=m.abs_color
	s.scatter_tex=m.scatter_tex
	s.scatter_color=m.scatter_color
	s.absorption_val=m.absorption_val
	s.absorption_tex=m.absorption_tex
	s.scatter_density=m.scatter_density
	s.scatter_density_tex=m.scatter_density_tex
	s.use_coeff=m.use_coeff
	s.coeff=m.coeff
	s.phase=m.phase-1
	s.asym=m.asym
	
	format "Converted to %\n" s to:templog	
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Thea Material (OLD) converted to "+s.name+":Thea_Material")
	windows.processPostedMessages()) catch()
	return s
)



-----------------------------------------------------------
---FUNCIONES PARA CONVERTIR A COLIMO---
-----------------------------------------------------------

fn vray2colimo origmtl= (			
				
	m = mental_ray ()
	m.surface = MColimoAuxChannel ()
	m.name = origmtl.name
	
	m.Surface.Reflection = origmtl.Reflection.value/255				
	
	if (override_glossy==false) then m.Surface.Glossy = origmtl.reflection_glossiness else m.Surface.Glossy=0.0
	if m.Surface.Glossy<0.3 then m.Surface.Glossy=0.0
	m.Surface.PrimarySamples = origmtl.reflection_subdivs
	m.Surface.SecondarySamples = origmtl.reflection_subdivs/2
	m.Surface.RestOfSamples = 1
	
	m.Surface.Refraction = origmtl.Refraction.value/255 
	m.Surface.ior = origmtl.refraction_ior
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayMtl converted to "+m.name+":Colimo")) catch()
	return m
)

fn std2colimo origmtl= (				
				
	m = mental_ray ()
	m.surface = MColimoAuxChannel ()
	m.name = origmtl.name
	
	--- refl
	m.Surface.Reflection = origmtl.specularLevel/100

	--- glossy
	if (override_glossy==false) then m.Surface.Glossy = origmtl.glossiness/100 else m.Surface.Glossy = 0.0  --fn_glossy fuera
	if m.Surface.Glossy<0.3 then m.Surface.Glossy=0.0
	--opacity
	m.Surface.Refraction = 1-(origmtl.opacity/100)
	m.Surface.ior = 1.0
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Standardmaterial converted to "+m.name+":Colimo")) catch()
	return m

)

fn MW2colimo origmtl = ( --maxwell 1.7 s髄o 1 capa
	
	numcapas = fn_capasmaxwell_old origmtl
	
	if numcapas == 2 then --se toman s髄o 2 como m醲imo
	(
		m = mental_ray ()
		m.name = origMtl.name
		m.surface = MColimoAuxChannel ()
		
		--primera capa
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:0
		peso_A = origMtl.Layer_Weight/100
		a_refr = origMtl.Transparency_Color.value/255*peso_A
		a_ior = origMtl.BSDF_Nd
	
		a_refl = origMtl.Fresnel_Color.value/255*peso_A
		a_glossy = (1-origMtl.BSDF_Roughness/100)*peso_A
		
		--segunda capa
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:1
		peso_B = origMtl.Layer_Weight/100
		b_refr = origMtl.Transparency_Color.value/255*peso_B
		b_ior = origMtl.BSDF_Nd
		
		b_refl = origMtl.Fresnel_Color.value/255*peso_B
		b_glossy = (1-origMtl.BSDF_Roughness/100)*peso_B
		
		m.surface.Reflection = a_refl+b_refl
		if (override_glossy==false) then m.surface.Glossy = (a_glossy+b_glossy) else m.surface.Glossy = 0.0
		if m.Surface.Glossy<0.3 then m.Surface.Glossy=0.0
		m.surface.Refraction = a_refr+b_refr
		m.Surface.ior = a_ior
		
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Maxwell_1.7 converted to "+m.name+":Colimo")) catch()
		return m
	)
	else
	(
		--vamos s髄o con una capa
		m = mental_ray ()
		m.surface = MColimoAuxChannel ()
		m.name = origMtl.name
		
		maxwellMaterialSetActiveLayer material:origMtl layerIndex:0

		if origMtl.Transparency_Color.value > 0 then 
		(
			m.Surface.Refraction = origMtl.Transparency_Color.value/255
			m.Surface.ior = origMtl.BSDF_Nd
		)

		if (override_glossy==false) then m.Surface.Glossy = (1-origMtl.BSDF_Roughness/100) else m.Surface.Glossy = 0.0
		if m.Surface.Glossy<0.3 then m.Surface.Glossy=0.0
		if origMtl.BSDF_Roughness < 40 then m.Surface.Reflection  = origMtl.Fresnel_Color.value/255 else m.Surface.Reflection = 0
		
		format "Converted to %\n" m to:templog
		try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Maxwell_1.7 converted to "+s.name+":Colimo")) catch()
		return m
	)
)

fn MW2colimo_v2 origmtl =( --maxwell 2 (futuro)
	numCapas = origmtl.layers.count
	for i = 1 to numCapas do
	(
		if (origmtl.Layers[i].blendmode == 0) then capabase = i
	)
	
)

fn vraybad2colimo origmtl =(
	
	m = mental_ray ()
	m.surface = MColimoAuxChannel ()
	m.name = origmtl.name
	
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":VrayBadMtl converted to "+m.name+":Colimo")) catch()
	return m
)

fn Arch2colimo origmtl =(
	
	m = mental_ray ()
	m.surface = MColimoAuxChannel ()
	m.name = origmtl.name
	
	--reflection
	if (origmtl.refl_hlonly==on) then m.Surface.Reflection = 0 else m.Surface.Reflection = origmtl.refl_weight*(origMtl.refl_color.value/255.0)
	if (override_glossy==false) then m.Surface.Glossy = origMtl.refl_gloss else m.Surface.Glossy = 0.0 --fn_glossy fuera
	if m.Surface.Glossy<0.3 then m.Surface.Glossy=0.0
	m.Surface.PrimarySamples = origmtl.refl_samples
	m.Surface.SecondarySamples = origmtl.refl_samples/2
	m.Surface.RestOfSamples = 1
	
	--refraction
	m.Surface.Refraction = origmtl.refr_weight
	m.Surface.ior = origmtl.refr_ior
		
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Arch___Design__mi converted to "+m.name+":Colimo")) catch()
	return m
)

fn thea2colimo origMtl = (
	
	m = mental_ray ()
	m.surface = MColimoAuxChannel ()
	m.name = origmtl.name
	format "Converted to %\n" m to:templog
	try(theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n"+origMtl.name+":Thea_Material converted to "+m.name+":Colimo")) catch()
)

-----------------------------------------------
---DISCRIMINADOR DE MATERIALES---
-----------------------------------------------

fn discrimina origMtl = (

	tipo=classof origMtl
	
--Tipo Multi	
	if (tipo==Multimaterial) then 
	(
		for i=1 to origMtl.materiallist.count do origMtl.materiallist[i]=discrimina origMtl.materiallist[i]
		return origMtl
	)
	
--Tipo Blend
	if (tipo==Blend) then
	(
		if (seltipo == "Colimo Aux. Shader") then --convertir blend a colimo
		(
			return vraybad2colimo origMtl
		)
		else
		(
			origMtl.map1 = discrimina origMtl.map1
			origMtl.map2 = discrimina origMtl.map2
			origMtl.mask = Validamapa origMtl.mask
		)
		return origMtl
	)
	
--Tipo DoubleSided
	if (tipo==DoubleSided) then
	(
		if (seltipo == "Colimo Aux. Shader") then --convertir blend a colimo
		(
			return vraybad2colimo origMtl
		)
		
		if (seltipo == "Thea Render") then origMtl=discrimina origMtl.material1
		else
		(
			origMtl.map1 = discrimina origMtl.material1
			origMtl.map2 = discrimina origMtl.material2
		)
		return origMtl
	)
	

--Tipo VRay

	if (tipo == VrayMtl) then
	(	
		
		if (seltipo == "Maxwell Render") then --convertir Vray a Maxwell
		(
			if renderers.current.version > 11 then return convertir_Vray_MW2 origMtl else	return convertir_Vray_MW origMtl 
		)
		if (seltipo == "Scanline") then --convertir Vray a Standard
		(
			return vray2std origMtl 	--por ahora sin reflexion ni refraccion
		)
		if (seltipo == "Vray") then --convertir Vray a Vray
		(
			format "% >> it's already a VRay material\n" origMtl to:templog 
			return origMtl			
		)
		if (seltipo == "Final Render") then --convertir Vray a Final Render
		(
			return format "FR conversion not available yet\n" to:templog
		)
		if (seltipo == "Mental Ray") then --convertir Vray a Mental
		(
			return vray2mrArchmaterial origMtl			
		)
		if (seltipo == "FryRender") then --convertir Vray a Fry
		(
			return vray2stdfry origMtl
		)
		if (seltipo == "Thea Render") then --convertir Vray a Thea
		(
			return vray2thea origMtl
		)
		if (seltipo == "Colimo Aux. Shader") then --convertir vray a colimo
		(
			return vray2colimo origMtl
		)
	) 

--Tipo VrayLightMtl

	if (tipo == VrayLightMtl) then
	(
		if (seltipo == "Maxwell Render") then --convertir a maxwell
		(
			if renderers.current.version > 11 then return vraylight2MW2_emitter origMtl else return vraylight2MW_emitter
		)
		
		if (seltipo == "FryRender") then --convertir VraylightMtl a Fry
		(
			return vraylight2stdfry origMtl
		)
		
		if (seltipo == "Mental Ray") then --convertir VraylightMtl a Mental
		(
			return vraylight2mental origMtl
		)
		
		if (seltipo == "Thea Render") then --convertir VraylightMtl a thea
		(
			return vraylightMtl2thea origMtl
		)
		
		if (seltipo == "Colimo Aux. Shader") then --convertir vraylight a colimo
		(
			return vraybad2colimo origMtl
		)
		return origMtl
		
	)
		
--Tipo VrayMtlWrapper
	if (tipo == vRayMtlWrapper) then
	(
		origMtl=discrimina origMtl.BaseMtl
		return origMtl
	)
	
--Tipo VrayblendMtl
	if (tipo == VRayBlendMtl) then
	(		
		if (seltipo == "Thea Render") then return vrayblendMtl2Thea origMtl else--convertir Vray a Thea
		(
			origMtl=discrimina origMtl.BaseMtl
			return origMtl
		)
	)
	
--Tipo Vray2sidedMtl
	if (tipo == VRay2SidedMtl) then
	(
		origMtl=discrimina origMtl.frontMtl
		return origMtl
	)
	
--Tipo standard
	
	if (tipo == Standardmaterial) then
	(
		if (seltipo == "Maxwell Render") then --convertir standard a Maxwell
		(
			if renderers.current.version > 11 then return std2MW2 origMtl else return std2MW origMtl
		)	
		if (seltipo == "Scanline") then --convertir Standard a Standard
		(
			format "% >> it's already a Standard material\n" origMtl to:templog
			return origMtl	
		)
		if (seltipo == "Vray") then --convertir Standard a Vray
		(
			return Std2vray origMtl
		)
		if (seltipo == "Final Render") then --convertir Standard a Final Render
		(
			format "FR conversion not available yet\n" to:templog
			return origMtl
		)
		if (seltipo == "Mental Ray") then --convertir standard a Mental
		(
			return std2mrArchmaterial origMtl
		)	
		if (seltipo == "FryRender") then --convertir Standard a Fry
		(
			return std2stdfry origMtl
		)
		if (seltipo == "Thea Render") then --convertir Standard a Thea
		(
			return std2thea origMtl
		)
		if (seltipo == "Colimo Aux. Shader") then --convertir standard a colimo
		(
			return std2colimo origMtl
		)
	)
	
--Tipo Maxwell

	if (tipo == MaxwellMaterial) then
	(
		if (seltipo == "Maxwell Render") then --convertir Maxwell a Maxwell
		(
			format "% >> it's already a Maxwell material\n" origMtl to:templog
			return origMtl
		)
		if (seltipo == "Scanline") then --convertir Maxwell a Standard
		(
			return MW2std origMtl 	
		)
		if (seltipo == "Vray") then --convertir Maxwell a Vray
		(
			return MW2Vray origMtl			
		)
		if (seltipo == "Final Render") then --convertir Maxwell a Final Render
		(
			return format "FR conversion not available yet\n" to:templog
		)
		if (seltipo == "Mental Ray") then --convertir Maxwell a Mental
		(
			return MW2mrArchmaterial origMtl			
		)
		if (seltipo == "FryRender") then --convertir Maxwell a Fry
		(
			return MW2std origMtl
		)
		if (seltipo == "Thea Render") then --convertir Maxwell a thea
		(
			return MW2thea origMtl
		)
		if (seltipo == "Colimo Aux. Shader") then --convertir maxwell a colimo
		(
			return MW2colimo origMtl
		)
	)
	
	if (tipo == Maxwell_Material) then
	(
		if (seltipo == "Maxwell Render") then --convertir Maxwell a Maxwell
		(
			format "% >> it's already a Maxwell material\n" origMtl to:templog
			return origMtl
		)
-- 		if (seltipo == "Scanline") then --convertir Maxwell a Standard
-- 		(
-- 			return MW2std_v2 origMtl 	
-- 		)
-- 		if (seltipo == "Vray") then --convertir Maxwell a Vray
-- 		(
-- 			return MW2Vray_v2 origMtl			
-- 		)
-- 		if (seltipo == "Final Render") then --convertir Maxwell a Final Render
-- 		(
-- 			return format "FR conversion not available yet\n" 
-- 		)
-- 		if (seltipo == "Mental Ray") then --convertir Maxwell a Mental
-- 		(
-- 			return MW2mrArchmaterial_v2 origMtl			
-- 		)
-- 		if (seltipo == "FryRender") then --convertir Maxwell a Fry
-- 		(
-- 			return MW2std_v2 origMtl
-- 		)
		if (seltipo == "Thea Render") then --convertir Maxwell a thea
		(
			return MW2thea_v2 origMtl
		)
-- 		if (seltipo == "Colimo Aux. Shader") then --convertir maxwell a colimo
-- 		(
-- 			return MW2colimo_v2 origMtl
-- 		)
	)
	
--Tipo mrArchMaterial
	if (tipo == Arch___Design__mi) then
	(
		if (seltipo == "Mental Ray") then --convertir Mental a Mental
		(
			format "% >> it's already a MentalRay material\n" origMtl to:templog
			return origMtl
		)	
		
		if (seltipo == "FryRender") then --convertir Mental a Fry
		(
			return mrArchmaterial2Fry origMtl
		)
		
		if (seltipo == "Maxwell Render") then --convertir Mental a Maxwell mrArchmaterial2Vray
		(
		if renderers.current.version > 11 then return mrArchmaterial2MW2 origMtl else return mrArchmaterial2MW origMtl
		)
		
		if (seltipo == "Vray") then --convertir Mental a VRay 
		(
			return mrArchmaterial2Vray origMtl
		)
		if (seltipo == "Thea Render") then --convertir Mental a thea 
		(
			return Mental2thea origMtl
		)
		
		if (seltipo == "Colimo Aux. Shader") then --convertir mental a colimo
		(
			return Arch2colimo origMtl
		)
	)
	
--Tipo Carpaint MR
	if (tipo==Car_Paint_Material__mi) then
	(
		if (seltipo == "Thea Render") then --convertir Carpaint Mental a Thea 
		(
			return CarMental2thea origMtl
		)
		if (seltipo == "Colimo Aux. Shader") then --convertir carpaint a colimo
		(
			return vraybad2colimo origMtl
		)
	)
	
--Tipo Thea Material
	if (tipo == Thea_Material or tipo==Thea_Basic or tipo==Thea_Glossy or tipo==Thea_SSS or tipo==Thea_Thinfilm or tipo==Thea_Coating \
		or tipo==Thea_Basic_Layer or tipo==Thea_Glossy_Layer or tipo==Thea_SSS_Layer or tipo==Thea_Thinfilm_Layer or tipo==Thea_Coating_Layer or tipo==Thea_Material_Old) then
	(
		if (seltipo == "Thea Render") then --convertir Thea a Thea
		(
			if (tipo == Thea_Material_Old) then --convertir old Thea material
			(
				return theaOld2theaNew origMtl
			) 
			else (
				format "% >> it's already a Thea material\n" origMtl to:templog
				return origMtl
			)
		)
		if (seltipo == "Colimo Aux. Shader") then --convertir vraylight a colimo
		(
			return vraybad2colimo origMtl
		)
	)
	
--Tipo Xref 
	if (tipo == XRef_Material) then
	(
		if (seltipo == "Colimo Aux. Shader") then --convertir xref a colimo
		(
			return vraybad2colimo origMtl
		)
		format "% >> it's a Xref material. Not converted.\n" origMtl to:templog
		return origMtl
		
	)
	
--Tipo undef
	
	if (tipo == UndefinedClass) then
	(
		if (seltipo == "Colimo Aux. Shader") then --convertir vraylight a colimo
		(
			return vraybad2colimo origMtl
		)
		format "Undefined material\n" to:templog
		return origMtl
	)

	if forzar then
	(	
		if (seltipo == "Mental Ray") then --convertir desconocido a mental
			(
				m= mrArchMaterial ()
				m.name=origMtl.name
				format "Forced material conversion %\n" origMtl to:templog
				return m
			)
		if (seltipo == "Scanline") then --convertir desconocido a standard
			(
				m= Standard()
				m.name=origMtl.name
				format "Forced material conversion %\n" origMtl to:templog
				return m
			)
		if (seltipo == "FryRender") then --convertir desconocido a Fry
			(
				m= FRY_Material ()
				m.name=origMtl.name
				format "Forced material conversion %\n" origMtl to:templog
				return m
			)
		if (seltipo == "Maxwell Render") then --convertir desconocido a Maxwell
			(
				if renderers.current.version > 11 then 
					(
						m= Maxwell_Material ()
						m.name=origMtl.name
						format "Forced material conversion %\n" origMtl to:templog
						return m
					) else
					(
						m= MaxwellMaterial ()
						m.name=origMtl.name
						format "Forced material conversion %\n" origMtl to:templog
						return m
					)
			)
		if (seltipo == "Vray") then --convertir desconocido a VRay
			(
				m= VRayMtl ()
				m.name=origMtl.name
				format "Forced material conversion %\n" origMtl to:templog
				return m
			)
		if (seltipo == "Thea Render") then --convertir desconocido a Thea
			(
				m= Thea_Material ()
				m.name=origMtl.name
				format "Forced material conversion %\n" origMtl to:templog
				return m
			)
		if (seltipo == "Colimo Aux. Shader") then --convertir vraylight a colimo
		(
			return vraybad2colimo origMtl
		)
	)
	else
	(
		format "% is not a valid material\n" origMtl to:templog
		return origMtl
	)
	
		
)

fn replaceMtlNode node origMtl newMtl = (
	if ((isValidNode node) and (node.material==origMtl)) then (
		node.material=newMtl
		format "    %\n" node.name to:templog
	)
	for i=1 to node.children.count do (
		replaceMtlNode node.children[i] origMtl newMtl
	)
)

	
fn reemplazaMtl origMtl newMtl = (
	
		if (origMtl!=newMtl) then replaceMtlNode rootNode origMtl newMtl
)



-------------------------------------------------------		
--CONVERSION DE LOS MATERIALES--
-------------------------------------------------------

fn convierteMats = (
	format "Material Converter v1.23\n\nConverting materials...\n\n" to:templog
	try(theObj.text = "Converting materials..."
	theobj.controls.item[0].hide()
	theObj.Controls.Item[1].text = "Analyzing scene... "
	theObj.Controls.Item[2].value = 1) catch()
	if (origtipo == 2) then --solo seleccionados
	(
		objetos = selection as array
		if (objetos==undefined) then return messagebox "there's no objects selected"
		num = objetos.count
		try(
			theObj.Show()
			windows.processPostedMessages()
		) catch()
		for i = 1 to num do
		(
			origMtl = objetos[i].material
			format "\n%\n" origMtl to:templog
			val = 100.0*i/(num as float)  --informacion en la barra de estado
			try(theObj.Controls.Item[2].value = val
			theObj.text = ("\nDone >>> "+val as string+"%")
			theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n...")
			windows.processPostedMessages()) catch()
			--crear el nuevo mat aparte de este		
			newMtl = discrimina origMtl		
			--meterlo en la escena		
			format "Applying material to...\n" to:templog
			reemplazaMtl origMtl newMtl			
			estado = "Done..."+val as string+"%"
			pushPrompt estado
			try(windows.processPostedMessages()) catch()
		)
		if (v[1]<17000) then (try(theObj.Dispose()) catch()) else (try(theObj.close()) catch()) --en el 2015 no va el dispose
		format "Material conversion finished\n\n% materials processed\n" num to:templog
	) else
	(
		num = geometry.count
		try(theObj.Show()
		windows.processPostedMessages()) catch()
		for i = 1 to num do 
		(
			origMtl = geometry[i].material
			format "\n%\n" origMtl to:templog
			val = 100.0*i/(num as float)  --informacion en la barra de estado
			try(theObj.text = ("\nDone >>> "+val as string+"%")
			theObj.Controls.Item[2].value = 100.0*i/(num as float)
			theObj.Controls.Item[1].text = ("Reading..."+origMtl.name+"\n...")
			windows.processPostedMessages()) catch()
			--crear el nuevo mat aparte de este	
			NewMtl = discrimina origMtl
		
			--meterlo en la escena
		
			format "Applying material to...\n" to:templog
			reemplazaMtl origMtl NewMtl
			estado = "Done..."+val as string+"%"
			pushPrompt estado
			try(windows.processPostedMessages()) catch()
		)
		v=maxversion()
		if (v[1]<17000) then (try(theObj.Dispose()) catch()) else (try(theObj.close()) catch()) --en el 2015 no va el dispose
		format "Material conversion finished\n\n% materials processed\n" num to:templog
	)
)
	
-------------------------------------
--CONVERSION DE CAMARAS--
-------------------------------------

fn cam2MWcam origCam = (

try (
	
		 if (classof origCam == VRayPhysicalCamera) then
		(
			objetivo = origCam.targeted
			if objetivo then (mw_cam = Targetcamera transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [1,1,1])))
				else (mw_cam = Freecamera transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]))
			mw_cam.pos = origCam.pos
			mw_cam.fov = origCam.focal_length
			mw_cam.clipManually = origCam.clip_on
			mw_cam.nearclip = origCam.clip_near
			mw_cam.farclip = origCam.clip_far
			mw_cam.name = (origCam.name as string + "_MW")
			if objetivo then (mw_cam.target.name = (mw_cam.name as string + ".Target")) else (mw_cam.targetDistance = origCam.target_distance)
			mw_cam.baseObject.Maxwell_Parameters.fStop = origCam.f_number
			mw_cam.baseObject.Maxwell_Parameters.shutterSpeed = origCam.shutter_speed
			mw_cam.baseObject.Maxwell_Parameters.filmISO = origCam.iso
			
			if animcam then
			(
				mw_cam.pos.controller = origCam.pos.controller
				if objetivo then (mw_cam.controller.roll_angle.controller = origCam.controller.roll_angle.controller) else (mw_cam.rotation.controller = origCam.rotation.controller)
				if objetivo then (mw_cam.target.pos.controller = origCam.target.pos.controller)
			)
			else
			(
				mw_cam.pos = origCam.pos
				if objetivo then (mw_cam.target.pos = origCam.target.pos) else mw_cam.rotation = origCam.rotation
			)
			
			format "Camera % converted to %\n" origCam.name mw_cam.name to:templog
			append camaras origCam
			append newcam mw_cam
		)
		
		if (classof origCam == VRayDomeCamera) then return format "Can't convert %. VrayDome camera not supported yet\n" origCam.name 
		
		if ((classof origCam == Targetcamera) or (classof origCam == Freecamera)) then return format "There is no need to convert % \n" origCam.name 
	
	
)
catch return format "Can't convert %\n" origCam.name to:templog

) --fin funcion cam2MWcam

fn cam2Frycam origCam = (

try (
	
		if (classof origCam == Targetcamera) then
		(
				fry_cam = FRY_Target transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [1,1,1]))
				fry_cam.pos = origCam.pos
				fry_cam.fov = origCam.fov
				nom = origCam.name as string + "_Fry"
				nom2 = nom + ".Target"
				fry_cam.name =nom
				fry_cam.target.name = nom2
					
				if animcam then
				(
					fry_cam.pos.controller = origCam.pos.controller
					fry_cam.controller.roll_angle.controller = origCam.controller.roll_angle.controller
					fry_cam.target.pos.controller = origCam.target.pos.controller
				)
				else
				(
					fry_cam.pos = origCam.pos
					fry_cam.target.pos = origCam.target.pos
				)
		)
		else if (classof origCam == Freecamera) then
		(
			fry_cam = FRY_Free transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1])
			fry_cam.fov = origCam.fov
			nom = origCam.name as string + "_Fry"
			fry_cam.name = nom
			
			if animcam then
			(
				fry_cam.pos.controller = origCam.pos.controller
				fry_cam.rotation.controller = origCam.rotation.controller
			)
			else
			(
				fry_cam.pos = origCam.pos
				fry_cam.rotation = origCam.rotation
			)
			
		)
		
		else if (classof origCam == VRayPhysicalCamera) then
		(
			fry_cam = FRY_Target transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [1,1,1]))
			fry_cam.pos = origCam.pos
			fry_cam.fov = origCam.focal_length
			nom = origCam.name as string + "_Fry"
			nom2 = nom + ".Target"
			fry_cam.name =nom
			fry_cam.target.name = nom2
				
			if animcam then
			(
				fry_cam.pos.controller = origCam.pos.controller
				fry_cam.controller.roll_angle.controller = origCam.controller.roll_angle.controller
				fry_cam.target.pos.controller = origCam.target.pos.controller
			)
			else
			(
				fry_cam.pos = origCam.pos
				fry_cam.target.pos = origCam.target.pos
			)
		)
		
		
		format "Camera % converted to %\n" origCam.name fry_cam.name 
		append camaras origCam
		append newcam fry_cam
	)
		
	catch 
	(
		return format "Can't convert %\n**%**" origCam.name (getCurrentException() )
	
	)
) --fin funcion cam2Frycam

fn cam2Theacam origCam = (
	
	try (
	
		if (classof origCam == Targetcamera) then
		(
			TheaCam = Thea_cam transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) 
			--TheaCam.TC_width=renderWidth
			--TheaCam.TC_height=renderHeight
			TheaCam.transform = origCam.transform
			TheaCam.TC_focal = (cameraFOV.FOVtoMM origCam.fov)
			nom = origCam.name as string + "_Thea"
			TheaCam.name =nom
								
			if animcam then
			try (
				numClaves=numkeys origCam.controller.position.controller
				claveInicio=getKeyTime origCam.controller.position.controller 1
				claveFin=getKeyTime origCam.controller.position.controller numclaves
				
				animate on (
					for t = claveInicio to claveFin do
					(
						at time t
							TheaCam.transform = origCam.transform
					)
				)
			) catch()
			format "Camera % converted to %\n" origCam.name TheaCam.name to:templog
			append camaras origCam
			append newcam TheaCam
		)
		else if (classof origCam == Freecamera) then
		(
			TheaCam = Thea_cam transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) 
			--TheaCam.TC_width=renderWidth
			--TheaCam.TC_height=renderHeight
			TheaCam.transform = origCam.transform
			TheaCam.TC_focal = (cameraFOV.FOVtoMM origCam.fov)
			nom = origCam.name as string + "_Thea"
			TheaCam.name =nom
			
			if animcam then
			(
				TheaCam.pos.controller = origCam.pos.controller
				TheaCam.rotation.controller = origCam.rotation.controller
			)
			format "Camera % converted to %\n" origCam.name TheaCam.name to:templog
			append camaras origCam
			append newcam TheaCam
		)
		else if (classof origCam == VRayPhysicalCamera) then
		(
			
			TheaCam = Thea_cam transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) 
			--TheaCam.TC_width=renderWidth
			--TheaCam.TC_height=renderHeight
			TheaCam.transform = origCam.transform
			TheaCam.TC_focal = cameraFOV.FOVtoMM origCam.focal_length
			nom = origCam.name as string + "_Thea"
			TheaCam.name =nom
				
			
			if animcam then
			(
				numClaves=numkeys origCam.controller.position.controller
				if numclaves>1 then
				(
					claveInicio=getKeyTime origCam.controller.position.controller 1
					claveFin=getKeyTime origCam.controller.position.controller numclaves
					
					animate on (
						for t = claveInicio to claveFin do
						(
							at time t
								TheaCam.transform = origCam.transform
						)
					)
				)
			)
			format "Camera % converted to %\n" origCam.name TheaCam.name to:templog
			append camaras origCam
			append newcam TheaCam
		)
		else if (classof origCam == FRY_Target) then
		(
			TheaCam = Thea_cam transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) 
			--TheaCam.TC_width=renderWidth
			--TheaCam.TC_height=renderHeight
			TheaCam.transform = origCam.transform
			TheaCam.TC_focal = cameraFOV.FOVtoMM origCam.fov
			nom = origCam.name as string + "_Thea"
			TheaCam.name =nom
								
			if animcam then
			(
				numClaves=numkeys origCam.controller.position.controller
				claveInicio=getKeyTime origCam.controller.position.controller 1
				claveFin=getKeyTime origCam.controller.position.controller numclaves
				
				animate on (
					for t = claveInicio to claveFin do
					(
						at time t
							TheaCam.transform = origCam.transform
					)
				)
			)
			format "Camera % converted to %\n" origCam.name TheaCam.name to:templog
			append camaras origCam
			append newcam TheaCam
		)
		else if (classof origCam == FRY_Free) then
		(
			TheaCam = Thea_cam transform:(matrix3 [1,0,0] [0,0,1] [0,-1,0] [1,1,1]) 
			--TheaCam.TC_width=renderWidth
			--TheaCam.TC_height=renderHeight
			TheaCam.transform = origCam.transform
			TheaCam.TC_focal = cameraFOV.FOVtoMM origCam.fov
			nom = origCam.name as string + "_Thea"
			TheaCam.name =nom
			
			if animcam then
			(
				TheaCam.pos.controller = origCam.pos.controller
				TheaCam.rotation.controller = origCam.rotation.controller
			)
			format "Camera % converted to %\n" origCam.name TheaCam.name to:templog
			append camaras origCam
			append newcam TheaCam
		)
		
	)
		
	catch 
	(
		return format "Can't convert %\n**%**\n" origCam.name (getCurrentException()) to:templog
	
	)
)

fn setupcam = (
camaras= #()
newcam= #()

sel = cameras as array
num = cameras.count
--print sel

if num>0 then (
	for i = 1 to num do 
		(
			if iskindof sel[i] camera do
			(
				if (seltipo=="Maxwell Render") then cam2MWcam sel[i] 
				--if (seltipo=="FryRender") then cam2Frycam sel[i]
				if (seltipo=="Thea Render") then cam2Theacam sel[i]
			)
		)
	) else ( 
		format "There's no cameras in scene\n" to:templog
		)
	if borracam then
	(
		delete camaras
	)
	else
	(
		for i = 1 to camaras.count do
		(
			format "Cameras % & % are in the same position\n" camaras[i].name newcam[i].name to:templog
		)
	)
	
)


-------------------------------------
--CONVERSION DE LUCES--
-------------------------------------

fn unidades =(
	
	mult=units.SystemScale
	case units.SystemType of
	(
		#Inches: th_unit_scale = 0.0254*mult
		#Feet: th_unit_scale = 0.3048*mult
		#Miles: th_unit_scale = 1609.344*mult
		#Millimeters: th_unit_scale = 0.001*mult
		#Centimeters: th_unit_scale = 0.01*mult
		#Meters: th_unit_scale = 1*mult
		#Kilometers: th_unit_scale = 1000*mult
		default: th_unit_scale = 1
	)
	th_unit_scale
)

fn mrportal2vray luz = (
	
		vl = VRayLight()
		vl.name = luz.name + "_vray"
		vl.type = 0
		
		vl.rotation = luz.rotation
		vl.pos = luz.pos
		vl.multiplier = luz.multiplier*30
		vl.size1 = luz.light_length/2
		vl.size0 = luz.light_width/2
		vl.skylightPortal = on
		
		format "Light % converted to %\n" luz.name vl.name to:templog
		append luces luz
		append newluz vl
		
		
) --fin funci髇 mrportal2vray

fn mrportal2thea luz =(

	tl_length = luz.light_length
	tl_width =  luz.light_width
	tl=plane length:tl_length width:tl_width pos:[0,0,0]
	tl.name = luz.name+"_thea"
	tl.lengthsegs = 1
	tl.widthsegs = 1
	tl.transform = luz.transform
	convertToMesh tl
	meshop.flipNormals tl #{1,2}
	
	ml=thea_material()
	ml.materialList[1]=undefined
	ml.name = luz.name+"_mat"
	ml.emit_enabled=on
	ml.emit_color = luz.rgbFilter
	ml.power = luz.multiplier*1500
	ml.unit = 6  --cd/m2
	ml.efficacy=90
	
	tl.material = ml
	
	if animluz then
	(
		tl.pos.controller = luz.pos.controller
		tl.rotation.controller = luz.rotation.controller
	)
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
)

fn vraylight2thea luz =(

	local power=0
	if luz.type== 0 then
	(
		
		u=luz.normalizeColor
		
		tl=plane()
		tl.name = luz.name+"_thea"
		tl.lengthsegs = 1
		tl.widthsegs = 1
		tl.length = luz.size1*2
		tl.width =  luz.size0*2
		tl.transform = luz.transform
		convertToMesh tl
		meshop.flipNormals tl #{1,2}
		
		ml=thea_material()
		ml.materialList[1]=undefined
		ml.name = luz.name+"_mat"
		ml.emit_enabled=on
		case u of
		(
			0: (	power=luz.multiplier*luz.size0*unit_factor*2*luz.size1*unit_factor*2*2.196
					ml.unit = 1  --W
			)
			
			1: (	power = luz.multiplier
					ml.unit = 4 --lm 
			)
			
			2: ( 	power = luz.multiplier*pi
					ml.unit = 5 --lm/m2
			)
			
			3: (	power = luz.multiplier
					ml.unit = 1  --W
			)
			
			4: (	power = luz.multiplier
					ml.unit = 3 --W/m2/sr
			)
		)
		
		ml.efficacy=90
		ml.emit_color = luz.color
		if (luz.texmap != undefined and luz.texmap_on) then
		(
			ml.emit_tex= ValidaMapaThea luz.texmap
		)
		ml.power = power --W
		print luz.multiplier
		tl.material = ml
		
		
		if animluz then
		(
			tl.pos.controller = luz.pos.controller
			tl.rotation.controller = luz.rotation.controller
		)
		format "Light % converted to %\n" luz.name tl.name to:templog
		append luces luz
		append newluz tl
	)
	if luz.type== 2 then
	(
		
		u=luz.normalizeColor
		
		tl=sphere()
		tl.name = luz.name+"_thea"
		tl.radius = luz.size0
		tl.transform = luz.transform
		
		ml=thea_material()
		ml.materialList[1]=undefined
		ml.name = luz.name+"_mat"
		ml.emit_enabled=on
		case u of
		(
			0: (	power=luz.multiplier*luz.size0*unit_factor*2*luz.size1*unit_factor*2*2.196
					ml.unit = 1  --W
			)
			
			1: (	power = luz.multiplier
					ml.unit = 4 --lm 
			)
			
			2: ( 	power = luz.multiplier*pi
					ml.unit = 5 --lm/m2
			)
			
			3: (	power = luz.multiplier
					ml.unit = 1  --W
			)
			
			4: (	power = luz.multiplier
					ml.unit = 3 --W/m2/sr
			)
		)
		
		ml.efficacy=90
		ml.emit_color = luz.color
		if (luz.texmap != undefined and luz.texmap_on) then
		(
			ml.emit_tex= ValidaMapaThea luz.texmap
		)
		ml.power = power --W
		print luz.multiplier
		tl.material = ml		
		
		if animluz then
		(
			tl.pos.controller = luz.pos.controller
			tl.rotation.controller = luz.rotation.controller
		)
		format "Light % converted to %\n" luz.name tl.name to:templog
		append luces luz
		append newluz tl
	)
)

fn freeArea2Thea luz =(
	
	tl=plane()
	tl.name = luz.name+"_thea"
	tl.lengthsegs = 1
	tl.widthsegs = 1
	tl.length = luz.light_length
	tl.width =  luz.light_Width
	tl.transform = luz.transform
	convertToMesh tl
	meshop.flipNormals tl #{1,2}
	
	ml=thea_material()
	ml.materialList[1]=undefined
	ml.name = luz.name+"_mat"
	ml.emit_enabled=on
	ml.efficacy=90	
	ml.power = luz.intensity/(luz.light_length* luz.light_Width*unit_factor*unit_factor)
	ml.unit = 6  --cd/m2
	
	if (luz.useKelvin==off) then ml.emit_color = luz.rgbFilter
	else ml.emit_color=fn_kelvin2rgb luz.kelvin
	
	tl.material = ml
	
	if animluz then
	(
		tl.pos.controller = luz.pos.controller
		tl.rotation.controller = luz.rotation.controller
	)
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
)

fn targetArea2Thea luz =(
	
	tl=plane()
	tl.name = luz.name+"_thea"
	tl.lengthsegs = 1
	tl.widthsegs = 1
	tl.length = luz.light_length
	tl.width =  luz.light_Width
	tl.transform = luz.transform
	convertToMesh tl
	meshop.flipNormals tl #{1,2}
	
	ml=thea_material()
	ml.materialList[1]=undefined
	ml.name = luz.name+"_mat"
	ml.emit_enabled=on
	ml.efficacy=90	
	ml.power = luz.intensity/(luz.light_length* luz.light_Width*unit_factor*unit_factor)
	ml.unit = 6  --cd/m2
	
	if (luz.useKelvin==off) then ml.emit_color = luz.rgbFilter
	else ml.emit_color=fn_kelvin2rgb luz.kelvin
	
	tl.material = ml
	
	if animluz then
	try (
		numClaves=numkeys luz.controller.position.controller
		claveInicio=getKeyTime luz.controller.position.controller 1
		claveFin=getKeyTime luz.controller.position.controller numclaves
		
		animate on (
			for t = claveInicio to claveFin do
			(
				at time t
					tl.transform = luz.transform
			)
		)
	)
	catch()
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
)

fn omni2Thea luz = (
			
	tl=Thea_Omni()
	tl.name = luz.name+"_thea"
	tl.ch_shadow=luz.castshadows
	tl.multiplier = luz.multiplier
	tl.transform = luz.transform
	tl.attn = luz.attenDecay
	tl.col = luz.rgb
	if (luz.projectorMap != undefined and luz.projector == on) then tl.light_tex = validamapathea luz.projectorMap
	
	if animluz then
	(
		tl.pos.controller = luz.pos.controller
		tl.rotation.controller = luz.rotation.controller
	)
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
	
)

fn target2Thea luz = (
	
	if luz.coneShape==1 then 
	(
		tl=Thea_Spot pos:[0,0,0] target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [1,1,1]))
		tl.spotfalloff = luz.falloff
		tl.spothot = luz.hotspot
	)
	else
	(
		tl=Thea_Projector pos:[0,0,0] target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [1,1,1]))
		tl.width = luz.hotspot
		tl.height = luz.aspect/luz.hotspot
	)
	tl.name = luz.name+"_thea"
	tl.ch_shadow=luz.castshadows
	tl.multiplier = luz.multiplier
	tl.transform = luz.transform
	tl.target.transform = luz.target.transform
	tl.attn = luz.attenDecay
	try(tl.col = luz.color) catch()
	try(tl.col=luz.rgb) catch()
	if (luz.projectorMap != undefined and luz.projector == on) then tl.light_tex = validamapathea luz.projectorMap
	
	if animluz then
	(
		try
		(
			tl.pos.controller = luz.pos.controller
			tl.controller.roll_angle.controller = luz.controller.roll_angle.controller
			tl.target.pos.controller = luz.target.pos.controller
		)
		catch()
	)
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
	
)

fn IESfree2Thea luz = (
	
	tl=Thea_IES()
	tl.name = luz.name+"_thea"
	tl.multiplier = 1
	tl.transform = luz.transform
	if luz.usekelvin==on then tl.col = fn_kelvin2rgb luz.kelvin else tl.col = luz.rgbFilter
	tl.iesfile=luz.webfile	
	
	if animluz then
	(
		tl.pos.controller = luz.pos.controller
		tl.rotation.controller = luz.rotation.controller
	)
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
	
)

fn IEStarget2Thea luz = (
	
	tl=Thea_IES()
	tl.name = luz.name+"_thea"
	tl.multiplier = 1
	tl.transform = luz.transform
	if luz.usekelvin==on then tl.col = fn_kelvin2rgb luz.kelvin else tl.col = luz.rgbFilter
	tl.iesfile=luz.webfile	
	
	if animluz then
	 try (
			numClaves=numkeys luz.controller.position.controller
			claveInicio=getKeyTime luz.controller.position.controller 1
			claveFin=getKeyTime luz.controller.position.controller numclaves
			
			animate on (
				for t = claveInicio to claveFin do
				(
					at time t
						tl.transform = luz.transform
				)
			)
		)
	catch()
	
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
	
)

fn VRayLight2mray luz = (
	
	if ((luz.type == 0) and (luz.skylightPortal == on)) then
	(
		vl = mr_Sky_Portal()
		vl.name = luz.name as string + "_Mental"
		vl.light_length = luz.size1*2
		vl.light_width = luz.size0*2
		vl.rotation = luz.rotation
		print vl.rotation
		vl.pos = luz.pos
		vl.mode = 0
		if luz.normalizeColor == 0 then vl.multiplier = luz.multiplier/30
		
		format "Light % converted to %\n" luz.name vl.name to:templog
		append luces luz
		append newluz vl
		
	)
	
	if ((luz.type == 0) and (luz.skylightPortal == off)) then
	(
		vl = Free_Light()
		vl.type = "Free_Rectangle"
		vl.distribution = 2
		vl.name = luz.name as string + "_Mental"
		vl.light_width = luz.size0*2
		vl.light_length = luz.size1*2
		vl.rotation = luz.rotation
		vl.intensityType = 0
		vl.intensity = luz.multiplier/pi*5.4
		vl.pos = luz.pos
		vl.rgbFilter = luz.color
		vl.baseObject.Area_Light_Sampling_Custom_Attribute.mr_NumAreaSamples = 16
		vl.castShadows = luz.castShadows
		vl.shadowGeneratorByName = "Ray Traced Shadows"
		vl.projector = luz.texmap_on
		vl.projectorMap = luz.texmap
		
		format "Light % converted to %\n" luz.name vl.name to:templog
		append luces luz
		append newluz vl
	)
	
	if (luz.type == 1)  then --si es una dome light usamos un skylight
	(
		vl = skylight()
		vl.name = luz.name as string + "_Mental"
		if luz.normalizeColor == 0 then vl.multiplier = luz.multiplier/30
		vl.rotation = luz.rotation
		vl.pos = luz.pos
		vl.sky_mode = 1
		vl.color = luz.color
		vl.sky_color_map_on = luz.texmap_on
		vl.sky_color_map = luz.texmap
		
		format "Light % converted to %\n" luz.name vl.name to:templog
		append luces luz
		append newluz vl
		
	)
	
	if (luz.type == 2)  then --si es una esf閞ica, con la free sphere
	(
		vl = Free_Light()
		vl.type = "Free_Sphere"
		vl.light_radius = luz.size0
		vl.name = luz.name as string + "_Mental"
		vl.pos = luz.pos
		vl.intensityType = 0
		vl.intensity = luz.multiplier/pi*5.4
		vl.rgbFilter = luz.color
		vl.baseObject.Area_Light_Sampling_Custom_Attribute.mr_NumAreaSamples = 16
		vl.castShadows = luz.castShadows
		vl.shadowGeneratorByName = "Ray Traced Shadows"
					
		format "Light % converted to %\n" luz.name vl.name to:templog
		append luces luz
		append newluz vl
	)
		
		
) --fin funci髇 VRayLight2mray

fn daylight2vray day = (    --a鷑 pendiente de uso
	
		vl = VRaySun()
		dayorig=day.name
		day.name = day.name as string + "_vray"
	
		AssemblyMgr.FilterAssembly day Light &lucecicas
		num = lucecicas.count
		for i=1 to num do
		(
			if classof lucecicas[i] == mr_Sun then
			(
				vl.rotation = lucecicas[i].rotation
				vl.pos = lucecicas[i].pos
				vl.intensity_multiplier = lucecicas[i].skymult
				day.sun = vl.name
			) else 
			
			(			
				if classof lucecicas[i] == IES_Sun then
				(
					vl.name = lucecicas[i].name as string + "_vray"
					vl.rotation = lucecicas[i].rotation
					vl.pos = lucecicas[i].pos
					vl.intensity_multiplier = lucecicas[i].multiplier/100000
				) else
				(
			
					if classof lucecicas[i] == Directionallight then
					(
						vl.name = lucecicas[i].name as string + "_vray"
						vl.rotation = lucecicas[i].rotation
						vl.pos = lucecicas[i].pos
						vl.intensity_multiplier = lucecicas[i].multiplier/32000
					) else
					(
			
						if ((classof lucecicas[i] == mr_Sky) or  (classof lucecicas[i] == IES_Sky) or (classof lucecicas[i] == Skylight)) then
						(
							environmentmap = VRaySky()
							day.sky = undefined
							
						)
					)
				)
			)
		)			
		
		
		format "Daylight Converted to %\n" day.name to:templog
		
		
		
) --fin funci髇 daylight2vray

fn VRayIES2Thea luz =(
	
	tl=Thea_IES()
	tl.name = luz.name+"_thea"
	tl.transform = luz.transform
	tl.iesfile=luz.ies_file
	if luz.color_mode==0 then (
		tl.luz_color_scale=1
		tl.col=luz.color
	) else (
		tl.luz_color_scale=2
		tl.luz_kelvin =luz.color_temperature
	)
	
	if animluz then
	(
		try(tl.pos.controller = luz.pos.controller
		tl.rotation.controller = luz.rotation.controller
		) catch()
	)
	format "Light % converted to %\n" luz.name tl.name to:templog
	append luces luz
	append newluz tl
)

fn setupluces = (
	
	luces = #()
	newluz = #()
	
	if lights.count > 0 then
	(
		for luz in lights where classOf luz == mr_Sky_Portal do

			(
				if (seltipo=="Vray") then mrportal2vray luz --mrskyportal a vraylight en modo skyportal
				if (seltipo=="Mental Ray") then format "% It's already a Mental Ray light\n" luz.name to:templog
				if (seltipo=="Thea Render") then mrportal2thea luz --mrskyportal a plano  con emitter de thea
			)
		
		for luz in lights where classOf luz == VRayLight do

			(
				if (seltipo=="Mental Ray") then VRayLight2mray luz --de vraylight a mrskyportal o freelight
				if (seltipo=="Vray") then format "% It's already a Vray light\n" luz.name to:templog --de vray a vray
				if (seltipo=="Thea Render") then VRayLight2thea luz --de vraylight a plano  con emitter de thea
			)
			
		for luz in lights where classOf luz == Free_Area do

			(
				if (seltipo=="Vray") then 
				(
					luz.shadowGeneratorByName = "VRayShadow"
					format "There is no need to convert %\n" luz.name to:templog --luces free_area
				)
				
				if (seltipo=="Mental Ray") then 
				(
					luz.shadowGeneratorByName = "Ray Traced Shadows"
					format "Shadow mode changed for %\n" luz.name to:templog --luces free_area
				)
				
				if (seltipo=="Thea Render") then freeArea2Thea luz
			
			)
			
		for luz in lights where classOf luz == Target_Area do

			(
				if (seltipo=="Vray") then 
				(
					luz.shadowGeneratorByName = "VRayShadow"
					format "Shadow mode changed for %\n" luz.name to:templog --luces target_area
				)
				
				if (seltipo=="Mental Ray") then 
				(
					luz.shadowGeneratorByName = "Ray Traced Shadows"
					format "Shadow mode changed for %\n" luz.name to:templog --luces target_area
				)
				
				if (seltipo=="Thea Render") then targetArea2Thea luz
				
			)
			
		for luz in lights where classOf luz == Omnilight do

			(
				if (seltipo=="Mental Ray") then
				(
					luz.raytracedShadows = on
					format "Shadow mode changed for %\n" luz.name to:templog --luces omni
				)
				
				if (seltipo=="Thea Render") then omni2Thea luz
			)
			
		for luz in lights where (classOf luz == TargetDirectionallight or classof luz == targetSpot) do

		(
			if (seltipo=="Mental Ray") then
			(
				luz.raytracedShadows = on
				format "Shadow mode changed for %\n" luz.name to:templog --luces omni
			)
			
			if (seltipo=="Thea Render") then target2Thea luz
		)
		
		for luz in lights where classOf luz == Free_light and luz.Distribution==3 do

			(
				if (seltipo=="Thea Render") then IESfree2Thea luz
			)
			
		for luz in lights where classOf luz == Target_light and luz.Distribution==3 do

			(
				if (seltipo=="Thea Render") then IEStarget2Thea luz
			)
			
		for luz in lights where classOf luz == VRayIES do

			(
				if (seltipo=="Thea Render") then VRayIES2Thea luz
			)
			
	) else
		(
			format "There's no lights in the scene\n" to:templog
		)
		
		if borraluz then
	(
		delete luces
	)
	else
	(
		for i = 1 to luces.count do
		(
			format "Lights % & % are in the same position\n" luces[i].name newluz[i].name to:templog
		)
	)
)

----------------------
--DESPLEGABLES--
----------------------

rollout roll_acerca "About..." width:496 height:100
(
	label lbl1 "Questions, bugs or whatever you want:" pos:[16,16] width:192 height:16
	HyperLink mail   "lab@motivacg.com" color:(color 177 88 27) pos:[16,32] width:180 height:15 address:"mailto:lab@motivacg.com"
	HyperLink web "www.motivacg.com" color:(color 177 88 27) pos:[16,50] width:192 height:16 address:"http://www.motivacg.com"
	label lbl3 "Script created on Jul,7 2005 by Alejandro Su醨ez." pos:[16,70] width:490 height:16
	label lbl4 "Last update on Feb,24 2011" pos:[16,85] width:490 height:16
	
)

rollout roll_maxwell "Maxwell" width:496 height:64
(
	checkbox chk_engine "Asign Maxwell as current render engine (if not yet)" pos:[32,8] width:312 height:16 enabled:true
	checkbox chk_crisnegros "Avoid black glasses (VRay)" pos:[32,40] width:312 height:16 enabled:true checked:true
)

rollout roll_mental "MentalRay" width:496 height:64
(
	checkbox chk_engine "Asign MentalRay as current render engine (if not yet)" pos:[32,16] width:312 height:16 enabled:true
	checkbox chk_expfoto "Activate photographic exposure (3dsmax2008+)" pos:[32,40] width:312 height:16 enabled:true
		
	on roll_mental close do
	(
		chk_engine.checked = false
		
	)
)

rollout roll_vray "Vray" width:496 height:64
(
	checkbox chk_engine "Asign Vray as current render engine (if not yet)" pos:[32,16] width:312 height:16 enabled:true
		
	on roll_vray close do
	(
		chk_engine.checked = false
		
	)
)

rollout roll_scanline "Scanline" width:496 height:64
(
	checkbox chk_engine "Asign Scanline as current render engine (if not yet)" pos:[32,16] width:312 height:16 enabled:true
	
	on roll_scanline close do
	(
		chk_engine.checked = false
		
	)
)

rollout roll_Thea "Thea Render" width:496 height:64
(
	checkbox chk_engine "Asign Thea Render as current render engine (recommended)" pos:[32,16] width:312 height:16 checked:true enabled:true
	checkbox chk_glass "Try to detect Thin Glass" pos:[32,36] width:312 height:16 checked:true enabled:true
	
	on roll_thea close do
	(
		chk_engine.checked = false
		
	)
)

rollout roll_colimo "Colimo Aux Shader" width:496 height:64
(
	checkbox chk_engine "Asign Mental Ray as current render engine (recommended)" pos:[32,16] width:312 height:16 checked:true enabled:true
	
	on roll_thea close do
	(
		chk_engine.checked = false
		
	)
)

rollout roll_camaras "Convert Cameras" width:496 height:48
(
	checkbox chk_animcam "Copy animation" pos:[48,16] width:111 height:16 enabled:true
	checkbox chk_borracam "Delete original cameras" pos:[200,16] width:144 height:16 enabled:true
)

rollout roll_luces "Convert Lights" width:496 height:48
(
	checkbox chk_animluz "Copy animation" pos:[48,16] width:111 height:16 enabled:true
	checkbox chk_borraluz "Delete original lights" pos:[200,16] width:144 height:16 enabled:true
)

rollout roll_mapas "Convert maps" width:496 height:112
(
	
	checkbox chk_proc "Process procedurals and unknown maps:" pos:[16,8] width:312 height:16 enabled:true checked:true
	edittext edit_dirproc "" pos:[40,51] width:248 height:20
	button bot_dirproc "..." pos:[288,49] width:24 height:24
	label etiq_dirproc "Output path:" pos:[40,32] width:160 height:16
	label lbl2 "Map size:" pos:[72,89] width:72 height:16
	spinner spin_anchoproc "Width:  " pos:[184,88] width:86 height:16 range:[0,4096,512] type:#integer scale:1
	spinner spin_altoproc "Height:  " pos:[304,88] width:78 height:16 range:[0,4096,512] type:#integer scale:1
	dropdownList drop_extension "File type:" pos:[320,33] width:64 height:40 items:#(".jpg", ".tga")
		
	
	on roll_mapas open do
	(
		
		edit_dirproc.text = getFilenamePath "$images"
		
		dirproc = getFilenamePath "$images"
	)
	on roll_mapas close do
	(
		chk_proc.checked = false
		
	)
	on bot_dirproc pressed do
	(
		pathproc = getSavePath caption:"Select output path for bitmaps"
		if pathproc != undefined then edit_dirproc.text = pathproc
		dirproc = edit_dirproc.text
		chk_proc.enabled = on
	)
)

rollout roll_opciones "Options" width:496 height:64
(
	checkbox chk_camaras "Convert cameras" pos:[32,8] width:312 height:16 enabled:true
	checkbox chk_forzar "Force unknown materials conversion" pos:[32,24] width:312 height:16 checked:true 
	checkbox chk_luces "Convert lights" pos:[32,40] width:312 height:16 enabled:true
	--checkbox chk_borraluces "Delete original lights" pos:[55,56] width:312 height:16 enabled:true
	
	on chk_camaras changed state do
	(
		if state==on then 
		(
			roll_camaras.chk_animcam.enabled = true
			roll_camaras.chk_borracam.enabled = true
		)
		else 
		(
			roll_camaras.chk_animcam.enabled = false
			roll_camaras.chk_borracam.enabled = false
		)
	)
	
	on chk_luces changed state do
	(
		if state==on then 
		(
			roll_luces.chk_animluz.enabled = true
			roll_luces.chk_borraluz.enabled = true
		)
		else 
		(
			roll_luces.chk_animluz.enabled = false
			roll_luces.chk_borraluz.enabled = false
		)
	)
)

rollout roll_general "Main" width:496 height:64
(
	dropdownList drop_origen "Convert..." pos:[24,8] width:160 height:40 items:#("whole scene...", "selected objects only...")
	dropdownList drop_destino "...to materials of type..." pos:[208,8] width:160 height:40 items:motores_destino
	on roll_general open do
	(
		
		origtipo = drop_origen.selection 
		seltipo = "Scanline" 
		messagebox seltipo
	)
)

rollout roll_acciones "备用：Vray材质转标准" width:496 height:56
(
	button bot_convertir "切换Start!"  width:80 height:80

		on bot_convertir pressed do
		(
			theObj = dotNetObject "MaxCustomControls.ProgressDialog"
			Environment = dotNetClass "System.Environment"
			sd = Environment.GetEnvironmentVariable "temp"
			logpath=(sd+"\\matconv_script.log")
			try(templog=createfile logpath) catch()
			--actionMan.executeAction 0 "40472"  --listener
			inicio = timeStamp () as float
			unit_factor = unidades()
			--print motores
			origtipo = 1
			seltipo = "Scanline"
			extension = roll_mapas.drop_extension.selected
			if roll_opciones.chk_forzar.checked then forzar = on else forzar = on
			if roll_maxwell.chk_crisnegros.checked then crisnegros = on else crisnegros = off
			if roll_camaras.chk_animcam.checked then animcam = on else animcam = off
			if roll_camaras.chk_borracam.checked then borracam = on else borracam = off
			if roll_luces.chk_borraluz.checked then borraluz = on else borraluz= off
			if roll_luces.chk_animluz.checked then animluz = on else animluz = off
			if roll_mapas.chk_proc.checked then procedural = on else procedural = off
			if roll_mental.chk_engine.checked then 
			(
				if (seltipo=="Mental Ray") then
				(
					if ((renderers.current as string) != "mental_ray_renderer:mental_ray_renderer") then renderers.current = mental_ray_renderer() else format "MentalRay is already the current renderer.\n" to:templog
				)
				if (renderSceneDialog.isOpen()) then renderSceneDialog.close()
				rendShowVFB = on
				if (classof environmentMap == VRaySky) then environmentmap = mr_Physical_Sky()
				if roll_mental.chk_expfoto.checked then try (SceneExposureControl.exposureControl = mr_Photographic_Exposure_Control()) catch (format "Photographic exposure only on 3dsmax2008 or higher\n" to:templog)
			)
			if (roll_general.drop_destino.selected=="FryRender") then
				(
					if roll_fry.chk_engine.checked then (if ((renderers.current as string) != "RandomControl_FRYRENDER:RandomControl_FRYRENDER") then renderers.current = RandomControl_FRYRENDER() else format "FryRender is already the current renderer.\n" to:templog)
				)
			if (seltipo=="Maxwell Render") then
				(
					if roll_maxwell.chk_engine.checked then 
					(
							n = renderers.current as string
							if (matchPattern n pattern:"MaxwellRenderer") then format "Maxwell is already the current renderer.\n" to:templog  else renderers.current = MaxwellRenderer()
					)
				)
			if (seltipo=="Vray") then
				(
					if roll_vray.chk_engine.checked then
					(
						n = renderers.current as string
						if ((matchPattern n pattern:"Vray*") or (matchPattern n pattern:"V_Ray*")) then format "VRay is already the current renderer.\n" to:templog else renderers.current = nombre_vray()
					)
				)
			if (seltipo=="Scanline") then
				(
					if roll_scanline.chk_engine.checked then (if ((renderers.current as string) != "Default_Scanline_Renderer:Default_Scanline_Renderer") then renderers.current = Default_Scanline_Renderer() else format "Scanline is already the current renderer.\n" to:templog)
				)
			if (seltipo=="Colimo Aux. Shader") then
				(
					if ((renderers.current as string) != "mental_ray_renderer:mental_ray_renderer") then renderers.current = mental_ray_renderer() else format "MentalRay is already the current renderer.\n" to:templog
				)	
			if (seltipo=="Thea Render") then
			(
				if roll_thea.chk_engine.checked then 
				(
					if ((renderers.current as string) != "Thea_Render:Thea_Render") then 
					(
						try(
							renderers.medit_locked=false
							renderers.current=Thea_render_max()
							renderers.medit_locked=true						
						) catch()
						try (renderers.activeShade=Thea_render_max()) catch()
						--renderers.medit = Default_Scanline_Renderer()
						try (SceneExposureControl.exposureControl = mr_Photographic_Exposure_Control()) catch ()
					) else format "Thea Render is already the current renderer.\n" to:templog
				)
			)

			anchoproc = roll_mapas.spin_anchoproc.value
			altoproc = roll_mapas.spin_altoproc.value
			convierteMats()
			if roll_opciones.chk_camaras.checked then setupcam()
			if roll_opciones.chk_luces.checked then setupluces()
			fin = timestamp () as float
			interv = ((fin - inicio)/1000) as float
			interv_out = "Process finished in "+interv as string+" seconds"
			format interv_out to:templog
			
			pushPrompt interv_out
			close templog
--			if queryBox "Do you want to se the log file showing all changes?" then (shelllaunch logpath "")
			--if (roll_general.drop_destino.selected=="FryRender") then messageBox "Final stage for Fry conversion must be done manually using quad menu (right click -> FRYRENDER Material Converter)" title:"Important"
		)
)	

if flota != undefined do closerolloutfloater flota
fn_motores()


----------UE4导出插件----------

	/* 
	Tom Shannon
	www.TomShannon3D.com
	
	Exports models to FBX one at a time. 
	Each FBX file will be named after the Max Scene name
	The models can be oriented to 0,0,0 on export (Rather than having them all stacked in MAX)
	You can export the position of the models to the clipboard for easy placing in UE4 by pasting the clipboard contents then replacing the placeholder objects in UE4 with the correct objects.
	
	Version 1.0 -	2014-07-22 : 	First version!
	Version 1.1 -	2014-09-07 : 	Collision features and some useability fixes, renamed
									NEW: Allows users to explicitly set the export directory. This stays saved in the max file permanently and will be reloaded
									NEW: Users can reset the saved export path to use the default export path
									NEW: Exports UCX collision geometry! Just ensure your naming is correct, and the script will detect the apropriate UCX primitives for export. Note: they do NOT need to be selected or visible!
	
									Fixed: Export Window now identifies errors and offers some helpful tootips
									Fixed: Export path textfield identifies when no export path is available
									Fixed: Interface updates when the max file is loaded, saved or reset, showing the correct paths, etc.
									Fixed: Disabled Geometry-specific export options when the object position is being exported (To help notify the user as to what mode they are in)
									Fixed: Checks to see if export path is valid and asks user if they want to create the export path if it doesn't exist, rather than just making one
	Version 1.1.1	2014-09-16 :	Fixed: Exporting objects now names objects correctly (Thanks, Maico G.!)
	*/
	
	try (destroyDialog UE4_Export_FBX_Rollout) catch ()
	
	ExportType = "Geometry" --legacy variable
	ExportObjects = #()
	OriginalSelection = #()
	
	defaultMeshPath = @"/Engine/EditorMeshes/EditorCube.EditorCube"
	
	--Strings for building things
	t3d_Header = 
"Begin Map
   Begin Level
"
t3d_StaticMesh_Entry = 
"      Begin Actor Class=StaticMeshActor Name=% Archetype=StaticMeshActor'/Script/Engine.Default__StaticMeshActor'
         Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0 ObjName=StaticMeshComponent0 Archetype=StaticMeshComponent'/Script/Engine.Default__StaticMeshActor:StaticMeshComponent0'
         End Object
         Begin Object Name=StaticMeshComponent0
            StaticMesh=StaticMesh'/Engine/EditorMeshes/EditorCube.EditorCube'
            RelativeLocation=(X=%,Y=%,Z=%)
            RelativeScale3D=(X=%,Y=%,Z=%)
            RelativeRotation=(Pitch=%,Yaw=%,Roll=%)
            CustomProperties 
         End Object
         StaticMeshComponent=StaticMeshComponent0
         Components(0)=StaticMeshComponent0
         RootComponent=StaticMeshComponent0
         ActorLabel=\"%\"
      End Actor
"

	  
t3d_Footer =
"   End Level
Begin Surface
End Surface
End Map
"

	global UE4_Export_FBX_Rollout = rollout UE4_Export_FBX_Rollout "虚幻4_FBX导出插件"
	(

		group  "导出模式"
		(
			radioButtons UE4_ObjectType labels:#("导出选中模型为FBX","剪切模型位置信息到剪切板") align:#left
		)
		
		group "导出设置"
		(
			checkbox UE4_UseGrid "使用用户网格（命名必须为\"UE4_Grid\")" enabled:false checked:true
			checkbox UE4_MoveToOrigin "移动到(0,0,0)导出" enabled:true checked:true
			checkbox UE4_IncludeCollision "包含UCX碰撞" across:2 checked:true
--			hyperlink hl2 "For More Information Click Here" address:"https://docs.unrealengine.com/latest/INT/Engine/Content/FBX/StaticMeshes/index.html#collision" color:(color 0 0 255) visitedColor:(color 0 0 255)

				
			checkbox UE4_Dialog "显示导出设置" checked:true 
			label label1 "导出路径:" align:#left
			edittext UE4_ExportPath_Text readonly:true  width:230 align:#left across:3 
			button UE4_SetExportPathButton "..."  height:17 width:17 offset:[110,0] tooltip:"选择导出路径"
			button UE4_ClearExportPathButton "X"  height:17 width:17 offset:[40,0] tooltip:"重置导出路径到此MAX文件目录"
			button OpenExportPathButton "打开导出路径"
		)
		
		listbox UE4_Listbox "即将被导出的模型:" readonly:true height:20
		button doit "导出选中模型" width:220 height:50	
		
--		hyperlink hl1 "Help and Info" address:"http://www.tomshannon3d.com/2014/07/tstools-first-release-ue4-mass-fbx.html" align:#center color:(color 0 0 255) visitedColor:(color 0 0 255)
		
		local doGridTransform = false
		local exportObjects = #()
		local selnames = #()
		local ErrorArray = #()
		local exportPath = undefined
		
		local layerNames = #()
		local layerObjects = #()
		
		local packageName = "" --do i still need this?
		
		fn updateExportPath =
		(
			-- If exportPath AND maxFilePath aren't set
			if maxfilepath == "" and ExportPath == undefined then 
				UE4_ExportPath_Text.text = "Please save the scene or specify an export path explicitly."
			
			-- If exportPath has NOT been defined and the scene file HAS been saved, assume the export path
			if exportPath == undefined and maxfilepath != "" do 
			(
				exportPath = maxfilepath+@"export\"
				UE4_ExportPath_Text.text = exportPath
			)
				
			--If there's an export path defined in the scene, use that instead
			SavedExportPath = (getAppData rootNode 77900)
			if (SavedExportPath != undefined) then 
			(
				exportPath = SavedExportPath
				UE4_ExportPath_Text.text = exportPath
			) 
		)		
		
		--Ensure there's a valid export path before exporting. If it's not there, ask the user if they want to create the path or cancel
		--Returns true if the directory exists or is created
		--Returns false if the director doesn't exist and the user says NO
		fn checkExportPath exportPathName =
		(
			if doesfileexist (exportPathName as String) == false then 
			(
				makeTheDir = queryBox (exportPathName as String +"\nDoes not exist.\nCreate this directory now?") title:"Export Directory Does Not Exist" beep:true
				if makeTheDir == true then
				(
					makeDir exportPathName
					return true
				)
				else return false
			)
			else return true
		)
		
		--Callback controls
		fn addCallbacks =
		(
			callbacks.addScript #selectionSetChanged "UE4_Export_FBX_Rollout.updateList()" id:#UE4_Export_FBX_Rollout_Update
			callbacks.addScript #filePostOpen "UE4_Export_FBX_Rollout.updateList resetExportPath:true" id:#UE4_Export_FBX_Rollout_Update
			callbacks.addScript #systemPostNew "UE4_Export_FBX_Rollout.updateList resetExportPath:true" id:#UE4_Export_FBX_Rollout_Update
			callbacks.addScript #systemPostReset "UE4_Export_FBX_Rollout.updateList resetExportPath:true" id:#UE4_Export_FBX_Rollout_Update
			callbacks.addScript #filePostSave "UE4_Export_FBX_Rollout.updateList()" id:#UE4_Export_FBX_Rollout_Update
		)
		
		fn removeCallbacks =
		(
			callbacks.RemoveScripts id:#UE4_Export_FBX_Rollout_Update
		)
		
		--return all collision shells matching the baseMesh's name
		fn findMatchingUCX baseMesh =
		(
			local matchingUCX = (execute ("$'UCX_"+baseMesh.name as string+"'*")) as array
			if matchingUCX != undefined then
				return matchingUCX
			else return false
		)
		
			
		
		--global updateList
		global updateList = fn updateList resetExportPath:false =
		(
			if resetExportPath==true do
				exportpath = undefined
			 
			--Actual objects to be exported!
			exportObjects = #()
			
			--Names, etc to populate the selection list. This veruable name is bad now because it handles some error strings as well!
			local selnames = #()
			
			--run the export path function to ensure the path is as up to date as possible
			updateExportPath()
			
			--Check to see if there's a UE4_Grid object in the scene, if so set the options
			if $UE4_Grid == undefined then
			(
				UE4_UseGrid.checked = false
				UE4_UseGrid.enabled = false
			)
			else UE4_UseGrid.enabled = true
			
			--Make sure there's something in the selection
			theSelection = selection as array
			OriginalSelection = selection as Array
			ErrorArray = #()
			
			--Do some basic error checking:
			--Ensure something is selected
			if theSelection.count == 0 do
			(
				append ErrorArray "    --Nothing Selected! "
				append ErrorArray "        Please select some meshes to export."
			)
			--Ensure there's something selected that can be exported, also build the exportObjects array that's used for the actual export
			for obj in theSelection do
			(
				if (superclassof obj == GeometryClass and classof obj != Targetobject and matchpattern obj.name pattern:"UCX_*" == false) do 
				(
					objName = obj.name
					append exportObjects obj
				)
			)
			if exportObjects.count == 0 and theSelection.count != 0 do 
			(
				append ErrorArray "    --No valid Geometry selected! "
				append ErrorArray "        Please select some non-UCX meshes to export."
			)
			--Check the valididty of the export path
			if exportPath == undefined do 
			(
				append ErrorArray "    --No Export Path Defined! Please define an export path above."
				append ErrorArray "        Please define an export path above."
			)
			
			
			if errorArray.count == 0 then
			(
				if UE4_ObjectType.state == 1 then append selnames (exportPath) --display the export path in the window
				else append selnames ("To be copied to Clipboard:")
				
				if exportObjects.count == 0 then
				(
					UE4_Listbox.items = #("No Valid Objects Selected! Only non-UCX geometry can be exported.")
					return true
				)
				
				-- build the .fbx  list (THIS IS PURELY for display!)
				for obj in exportObjects do
				(
					objName = obj.name
					if UE4_ObjectType.state == 1 then
					(
						if UE4_UseGrid.checked == false then tempString = "  "+objName+".fbx @ "+obj.pos as string
							else tempString = "  "+objName+".fbx @ "+(obj.pos-$UE4_Grid.pos) as string+" relative to UE4_Grid.pos"
						if UE4_MoveToOrigin.checked == true do tempString = "  "+objName+".fbx @ 0,0,0"
							
					)
					if UE4_ObjectType.state == 2 then
					(
						if UE4_UseGrid.checked == false then tempString = "  "+objName+" @ "+obj.pos as string
							else tempString = "  "+objName+" @ "+(obj.pos-$UE4_Grid.pos) as string+" relative to UE4_Grid.pos"
					)
					
					append selnames tempString
					
					if UE4_IncludeCollision.checked == true and UE4_ObjectType.state == 1 do
					(
						for UCX in (findMatchingUCX obj) do append selnames ("    "+UCX.name as string)
					)
				)

				if (selnames.count > 0 )then
					UE4_Listbox.items = selnames
					
			)-- END if selection.count != 0 then
			else
			(
				append selnames ("There are errors; can't build the object list:" as string)
				join selnames ErrorArray
				UE4_Listbox.items = selnames
			)
			
		)-- end function updateList
		

		on UE4_ObjectType changed newState do
		(
			if Newstate == 1 then
			(
				UE4_UseGrid.enabled = true 
				UE4_MoveToOrigin.enabled = true
				UE4_IncludeCollision.enabled = true 
				UE4_Dialog.enabled = true 
			)
			else
			(
				UE4_UseGrid.enabled = false 
				UE4_MoveToOrigin.enabled = false
				UE4_IncludeCollision.enabled = false 
				UE4_Dialog.enabled = false 
			)
			updatelist()
		)
		
		
		on UE4_Export_FBX_Rollout open do
		(
			updateList()
			addCallbacks()
		)
		
		on UE4_Export_FBX_Rollout close do
		(
			removeCallbacks()
			UE4_Export_FBX_Rollout = null
		)
		
		on UE4_SetExportPathButton pressed do                                                    
		(
			--Open to a resonable location
			if (doesfileexist (exportPath as String)) then thePath = getSavepath initialDir:(exportPath)
			else thePath = getSavepath initialDir:(maxfilepath)
			print thePath
			
			--Once set, save the path to the scene's appdata
			if thePath != undefined then 
			(
				exportPath = thePath
				SetAppData rootNode 77900 exportPath
			)
				
			updateList()
		)
		
		on UE4_ClearExportPathButton pressed do
		(
			exportPath = undefined
			deleteAppData rootNode 77900
			updateList()
		)
		
		
		--Refresh the List/UI when otions are changed, etc.
		on UE4_UseGrid changed newState do updateList()
		on UE4_Dialog changed newState do updateList()
		on UE4_MoveToOrigin changed newState do updateList()
		on UE4_IncludeCollision changed newState do updateList()
		
		
		on OpenExportPathButton pressed do
		(
			if exportPath != undefined then
				if (checkExportPath exportPath == true) then shellLaunch "explorer.exe" exportPath
			else 
				messageBox "No export path is defined."
		)
		
		--
		--
		--//* THIS IS THE BIG BUTTON PRESS FUCTIONALITY!!
		--
		--
		on doit pressed do
		(
			updateList()
			
			if ErrorArray.count != 0 do
			(
				ErrorMessage = ""
				for e in errorArray do append ErrorMessage ("\n"+e as string)
				messagebox ("Cannot export at this time:\n"+ ErrorMessage)
				return false
			)
			
			--Getting the options here for easy reference
			doGridTransform = UE4_UseGrid.checked
			doOrigin = UE4_MoveToOrigin.checked 
			dot3d = UE4_ObjectType.state == 2
			doGeom = UE4_ObjectType.state == 1
			doUCX = UE4_IncludeCollision.checked
			
			doDialog = UE4_Dialog.checked
			
			--Using the exportObjects generated by updateList to determine what to export
			--Probably don't need this anymore
			theSel = exportObjects
			
			--we need to 'pause' the callbacks in the script while we do this
			removeCallbacks()
			
			-- for speed
			max create mode
			
			--Here's where we create our selection arrays
			selectionArrays = #()
			
			-- Begin the t3d stringstream if we're doing that
			if (dot3d == true) do 
			(
				local t3dFile = stringstream ""
				format t3d_Header to:t3dFile
			)
			
			--ensure there's a directory to export to
			if (doGeom == true) do makeDir exportPath all:true
			
			--This is so we only show the FBX window the first time
			firstObject = true
			for obj in exportObjects do
			(
				objName = obj.name
				--select obj
				--Geometry/fbx
				if (doGeom == true) then
				(
					if doUCX then select (append (findMatchingUCX obj) obj)
					else select obj
					--print ("SLKAJSLDKJALSKDJALKSJDLAKSJDLAKSJDLKAJSDLKJASLDKJASLDJK")
					local objectShift = [0,0,0] --to be able to shift the collision shells if needed
					local exportFileName = exportPath+@"\"+objName+@".fbx"
					
					local objTransform = copy obj.transform
					
					--Get the shift based on user options
					if (doGridTransform == true and $UE4_Grid != undefined) then
					(
						objectShift = $UE4_Grid.pos
						
						if doOrigin == true do 
							objectShift = obj.pos - $UE4_Grid.pos
						
					)
					else if doOrigin == true then 
						objectShift = obj.pos
					
					--move everything
					for o in selection do 
						o.pos = o.pos - objectShift
					
					--Export selected!
					--Show the FBX dialog
					if firstObject == true and doDialog == true then 
						exportFile exportFileName selectedOnly:true
					
					else
						exportFile exportFileName #noPrompt selectedOnly:true
					
					firstObject = false
					
					--Move everything back
					for o in selection do 
						o.pos = o.pos + objectShift
					
				)		
				
				

				--.t3d --Now it just adds the text to the clipboard
				if (dot3d == true) then
				(
					
					--Default transformations
					local OBJRot = (matrix3 1).rotationpart as eulerangles 
					local OBJPos = [0,0,0]
					
					if (doGridTransform and $UE4_Grid != undefined) then
					(
						OBJRot = obj.transform.rotationpart as eulerangles 
						OBJPos = obj.pos - $UE4_Grid.pos
						
					)
					else
					(
						OBJRot = obj.transform.rotationpart as eulerangles 
						OBJPos = obj.pos
					)

					
					if superclassof obj == GeometryClass do
						format t3d_StaticMesh_Entry objName OBJPos.x (OBJPos.y*-1) OBJPos.z obj.scale.x obj.scale.y obj.scale.z (OBJRot.y*-1.0) (OBJRot.z*-1.0) OBJRot.x  objName to:t3dFile
				)
			)
			
			--Close off the t3d file if it's being made
			if (dot3d == true) then 
			(
				
				format t3d_Footer to:t3dFile
				setClipBoardText  t3dFile
				free t3dfile
			)
			
			select exportObjects
			updateList()
			addCallbacks()
		) --end on doit pressed do
		
	) -- end rollout

------------------------------------------------Vray转Scanline功能----------------------------------------------------

----------Init DiffuseMap and BumpMap----------

fn InitDiffuseMap MapPath objs =
(
	try
	(
		if MapPath != "" then
		(
			objs.material.diffuseMap = Bitmaptexture filename:MapPath
			objs.material.diffuseMap.filename = MapPath
			objs.material.DiffuseMap.coords.u_tiling = 1
			objs.material.DiffuseMap.coords.v_tiling = 1
		)
	)
	catch(print objs.name)
)

fn InitBumpMap MapPath objs = 
(
	try
	(
		if MapPath != "" then
		(
			objs.material.BumpMap = Bitmaptexture filename:MapPath
			objs.material.BumpMap.filename = MapPath
			objs.material.BumpMap.coords.u_tiling = 1
			objs.material.BumpMap.coords.v_tiling = 1
		)
	)
	catch(print objs.name)
)

fn InitDiffuseMapMulti MapPath objs index =
(
	try
	(
		if MapPath != "" then
		(
			objs.material[index].diffuseMap = Bitmaptexture filename:MapPath
			objs.material[index].diffuseMap.filename = MapPath
			objs.material[index].DiffuseMap.coords.u_tiling = 1
			objs.material[index].DiffuseMap.coords.v_tiling = 1
		)
	)
	catch(print objs.name)
)

fn InitBumpMapMulti MapPath objs index = 
(
	try
	(
		if MapPath != "" then
		(
			objs.material[index].BumpMap = Bitmaptexture filename:MapPath
			objs.material[index].BumpMap.filename = MapPath
			objs.material[index].BumpMap.coords.u_tiling = 1
			objs.material[index].BumpMap.coords.v_tiling = 1
		)
	)
	catch(print objs.name)
)

----------Single Convert----------

fn ConvertVrayMtlToStandard objs = 
(
	local SaveDiffuseMap = ""
	local SaveBumpMap = ""
	try (SaveDiffuseMap = objs.material.diffusemap.filename) catch ()
	try (SaveDiffuseMap = objs.material.texmap_diffuse.filename) catch()
	try (SaveBumpMap = objs.material.bumpmap.filename) catch ()
	try (SaveBumpMap = objs.material.bumpmap.bump_map.filename) catch ()
	objs.material = Standardmaterial()
	InitDiffuseMap SaveDiffuseMap objs
	InitBumpMap SaveBumpMap objs
)

fn ConvertVrayLightMtlToStandard objs = 
(
	local SaveDiffuseMap = ""
	try (SaveDiffuseMap = objs.material.texmap_diffuse.filename) catch ()
	objs.material = Standardmaterial()
	InitDiffuseMap SaveDiffuseMap objs
)

fn ConvertVrayMtlWrapperToStandard objs =
(
	local SaveDiffuseMap = ""
	local SaveBumpMap = ""
	try (SaveDiffuseMap = objs.material.baseMtl.diffusemap.filename) catch ()
	try (SaveDiffuseMap = objs.material.baseMtl.texmap_diffuse.filename) catch()
	try (SaveBumpMap = objs.material.baseMtl.bumpmap.filename) catch ()
	try (SaveBumpMap = objs.material.baseMtl.bumpmap.bump_map.filename) catch ()
	objs.material = Standardmaterial()
	InitDiffuseMap SaveDiffuseMap objs
	InitBumpMap SaveBumpMap objs
)

----------Multi\Object Convert----------

fn ConvertVrayMtlToStandardMulti objs index =  
(
	local SaveDiffuseMap = ""
	local SaveBumpMap = ""
	try (SaveDiffuseMap = objs.material[index].diffusemap.filename) catch ()
	try (SaveDiffuseMap = objs.material[index].texmap_diffuse.filename) catch()
	try (SaveBumpMap = objs.material[index].bumpmap.filename) catch ()
	try (SaveBumpMap = objs.material[index].bumpmap.bump_map.filename) catch ()
	objs.material[index] = Standardmaterial()
	InitDiffuseMapMulti SaveDiffuseMap objs index
	InitBumpMapMulti SaveBumpMap objs index
)

fn ConvertVrayLightMtlToStandardMulti objs index = 
(
	local SaveDiffuseMap = ""
	try (SaveDiffuseMap = objs.material[index].texmap_diffuse.filename) catch ()
	objs.material[index] = Standardmaterial()
	InitDiffuseMapMulti SaveDiffuseMap objs index
)

fn ConvertVrayMtlWrapperToStandardMulti objs index =
(
	local SaveDiffuseMap = ""
	local SaveBumpMap = ""
	try (SaveDiffuseMap = objs.material[index].baseMtl.diffusemap.filename) catch ()
	try (SaveDiffuseMap = objs.material[index].baseMtl.texmap_diffuse.filename) catch()
	try (SaveBumpMap = objs.material[index].baseMtl.bumpmap.filename) catch ()
	try (SaveBumpMap = objs.material[index].baseMtl.bumpmap.bump_map.filename) catch ()
	objs.material[index] = Standardmaterial()
	InitDiffuseMapMulti SaveDiffuseMap objs index
	InitBumpMapMulti SaveBumpMap objs index
)

----------Start Convert Logic----------

fn DoConvertOnce objs = 
(
	if (matchpattern (objs.material as string) pattern:"*VrayMtlWrapper*") then
	(
		--messagebox "This is VRMtlWrapper"
		ConvertVrayMtlWrapperToStandard objs
	)
	else if (matchpattern (objs.material as string) pattern:"*VrayMtl*") then
	(
		--messagebox "This is VRMtl"
		ConvertVrayMtlToStandard objs
	)
	else if (matchpattern (objs.material as string) pattern:"*VrayBlendMtl*") then
	(
		--messagebox "This is VRBlendMtl"
		ConvertVrayMtlWrapperToStandard objs --逻辑内容与Wrapper材质一致
	)
	else if (matchpattern (objs.material as string) pattern:"*VrayOverrideMtl*") then
	(
		--messagebox "This is VrayOverrideMtl"
		ConvertVrayMtlWrapperToStandard objs --逻辑内容与Wrapper材质一致
	)
	else if (matchpattern (objs.material as string) pattern:"*VrayLightMtl*") then
	(
		--messagebox "This is VrayLightMtl"
		convertVrayLightMtlToStandard objs
	)
	else
	(
		--messagebox "This is not VrayMaterial"
	)
)

fn DoConvertMulti objs index = 
(
	if (matchpattern (objs.material[index] as string) pattern:"*VrayMtlWrapper*") then
	(
		--messagebox "This is VRMtlWrapper"
		ConvertVrayMtlWrapperToStandardMulti objs index
	)
	else if (matchpattern (objs.material[index] as string) pattern:"*VrayMtl*") then
	(
		--messagebox "This is VRMtl"
		ConvertVrayMtlToStandardMulti objs index
	)
	else if (matchpattern (objs.material[index] as string) pattern:"*VrayBlendMtl*") then
	(
		--messagebox "This is VRBlendMtl"
		ConvertVrayMtlWrapperToStandardMulti objs index--逻辑内容与Wrapper材质一致
	)
	else if (matchpattern (objs.material[index] as string) pattern:"*VrayOverrideMtl*") then
	(
		--messagebox "This is VrayOverrideMtl"
		ConvertVrayMtlWrapperToStandardMulti objs index--逻辑内容与Wrapper材质一致
	)
	else if (matchpattern (objs.material[index] as string) pattern:"*VrayLightMtl*") then
	(
		--messagebox "This is VrayLightMtl"
		convertVrayLightMtlToStandardMulti objs index
	)
	else
	(
		--messagebox "This is not VrayMaterial"
	)
)

----------Main----------


rollout VrayConvertToScanline "Vray材质转标准"
(
	Button ConvertSelect "转换选中内容"
	Button ConvertAll "转换所有内容"
	
	on ConvertSelect pressed do
	(
		for objs in selection do
		(
			if (matchpattern (objs.material as string) pattern:"*Multi*") then
			(
				objs.material = copy objs.material
				--messagebox "MultiMaterial"
				local MaterialIndex = 1
				while MaterialIndex <= objs.material.count do
				(
					DoConvertMulti objs MaterialIndex
					MaterialIndex += 1
				)
			)
			else
			(
				--messagebox "SingleMaterial"
				DoConvertOnce objs
			)
		)
	)
	
	on ConvertAll pressed do
	(
		for objs in $* do
		(
			if (matchpattern (objs.material as string) pattern:"*Multi*") then
			(
				objs.material = copy objs.material
				--messagebox "MultiMaterial"
				local MaterialIndex = 1
				while MaterialIndex <= objs.material.count do
				(
					DoConvertMulti objs MaterialIndex
					MaterialIndex += 1
				)
			)
			else
			(
				--messagebox "SingleMaterial"
				DoConvertOnce objs
			)
		)
	)
)
----------------------


rollout rollout01 "顶点AO" category:14
(
  button btn_pressme "开始烘焙"
  on btn_pressme pressed do
  (
 -- Bake AO and Shadow Fuction..........................................................................................
 
 
--     fn get_batch =
-- 	(
-- 	registry.openKey HKEY_LOCAL_MACHINE "Software\Microsoft\Windows\CurrentVersion\Uninstall\faogen3" accessRights:#readOnly key:&key
-- 	if key != undefined then
-- 	(
-- 		registry.queryValue key "UninstallString" type:&type value:&uninst_cmd
-- 		if uninst_cmd != undefined then
-- 			substituteString uninst_cmd "uninstall.exe" "faogenbatch.exe"
-- 		)
-- 	)

-- create temporary copy for exporting
	fn copy_object obj prefix =
	(
	if obj.category != #Editable_Objects then converttopoly obj -- fix a weird bug with unecessary faces generated on some primitives (teapot) directly converted in "editable_mesh"
	convertToMesh obj
	obj_copy = copy obj
	id = formattedPrint obj.inode.handle format:"x"
	obj_copy.name = prefix+id
	obj_copy
	)	

-- assing vertex colors from src object to dst
	fn assign_vcolors src dst =
	(
	if src.faces.count == dst.faces.count then
	(
		meshop.setMapSupport dst 0 true
		numverts = meshop.getNumMapVerts src 0
		meshop.setNumMapVerts dst 0 numverts
		for i = 1 to numverts do
		(
			v = meshop.getMapVert src 0 i
			meshop.setMapVert dst 0 i v
		)
		
		for i = 1 to meshop.getNumMapFaces src 0 do
		(
			f = meshop.getMapFace src 0 i
			meshop.setMapFace dst 0 i f
		)
		
		dst.showVertexColors = true
		dst.vertexColorsShaded = false
		dst.vertexColorMapChannel = 0
		dst.vertexColorType = #color 
		)
	)

	
			--disableSceneRedraw()
			infile = getDir #userScripts+"Zowee_in.fbx"
			outfile = getDir #userScripts+"Zowee_out.fbx"
			
			try (
				deletefile infile
				deletefile outfile
			)
			catch()
		undo off(
			temppath = getDir #userScripts + "/ZoweeScripts" + "/temp.exe"
			cmdline = "call " + "\""+ temppath +"\""+ " -i \""+infile+"\" -o \""+outfile+"\" -vert -only Zoweebake# -q 50 -hemiZ"
			--if ui_hemi.checked then
				--cmdline += " -hemiZ"
			
			cloned_selection = for obj in selection where not obj.ishidden collect copy_object obj "Zoweebake#"
			cloned_env = #()			

			--if ui_env.checked then
			--(
				--max select invert
				--deselect cloned_selection
				--cloned_env = for obj in selection where not obj.ishidden collect copy_object obj "faogenoccl#"
				--select cloned_env
			--)
			--else 
			clearSelection()
			
			
			selectmore cloned_selection
			exportfile infile #noprompt selectedOnly:true
			delete cloned_selection
			delete cloned_env
			
			HiddenDOSCommand cmdline
			
			importfile outfile #noprompt

			
			for obj in geometry where substring obj.name 1 10 == "Zoweebake#" do
			(
				id = bit.hexasint (substring obj.name 11 100)
				dst = maxOps.getNodeByHandle id
				assign_vcolors obj dst
			)
			
			loaded_objects = for obj in geometry where substring obj.name 1 10 == "Zoweebake#"  collect obj
			delete loaded_objects
			
			select (for obj in geometry where classof obj == Editable_mesh collect obj)
			max zoomext sel
		)
			
			enableSceneRedraw()

   )

)








rollout rollout08 "材质球命名" width:132 height:110 category:8
(button btn_pressme "开始命名"
   on btn_pressme pressed do
(
	
	
	sel=selection as array 
		for i=1 to sel.count do
   (
			
	for m = 1 to 50 do														 --遍历24个材质球
		(
			if classof sel[i] .material != Multimaterial 
				then sel[i].material.name=sel[i].name+"M001" else
			(
				Mul = copy sel[i].material
				 sel[i].material=Mul
			   Mul.name= sel[i].name+i as string 
				for j = 1 to Mul.materialList.count do
				(
							
											--将空材质转换为标准StandardMaterial材质
							
					if  Mul.materialList[j].name != "" do Mul.materialList[j].name = ""	
						Mul.materialList[j].name  =sel[i].name+"M00"+ j as string 
					
				)
			)
			max mtledit
		)
          

	)
)
)






rollout rollout10 "烘培AO贴图" width:132 height:110 category:10
(    
   button btn_pressme "烘焙AO贴图"
    button btn_pressme2 "显示AO贴图"
   spinner SizeAO"贴图: " range:[0,4096,1024] type:#integer

on btn_pressme pressed do 
	
(
	if maxfilepath==""then
messagebox "请保存文件"
for m = 1 to 24 do	
(		
		if classof $ .material != Multimaterial 
				then ($.material.glossinessMap = undefined
			 
				)
			else(
			
				  Mul = $.material
				for j = 1 to Mul.materialList.count do
				(
							Mul.materialList[j].glossinessMap=undefined
							
			)
			max mtledit
		)
	)
if $.material==undefined  then messagebox "请给物体赋予材质"
	--global SHAD=getNodeByName ($.name)
global aa=copy $
aa.name=$.name
aa = (for aa in selection where (isKindOf aa GeometryClass and canConvertTo aa Editable_Mesh) collect aa)
		
		-- checks to see if anything will be unwrapped, and generates error popup if not
		if aa.count == 0 then messagebox "No suitable geometry selected!"
		else
		(
			clearSelection()	-- clears selection once original selection has been saved as aa array

			for i in 1 to aa.count do	-- loops through array of suitable geometry
			(
				select aa[i]	-- selects "i"th piece of geometry
					
				-- main UVW block
				modPanel.addModToSelection (Unwrap_UVW ()) ui:on
				aa[i].modifiers[#Unwrap_UVW].unwrap.setMapChannel 0
				aa[i].modifiers[#Unwrap_UVW].unwrap.move ()
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 0
				aa[i].modifiers[#Unwrap_UVW].baseMaterial_list.count = 1
				aa[i].modifiers[#Unwrap_UVW].baseMaterial_list[1] = undefined
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 1
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 1
				aa[i].modifiers[#Unwrap_UVW].texMapList[1] = Checker ()
				aa[i].modifiers[#Unwrap_UVW].texMapIDList[1] = -1
				subobjectLevel = 3
				actionMan.executeAction 0 "40021"
				max select all
				aa[i].modifiers[#Unwrap_UVW].flattenMap 45.0 #([1,0,0], [-1,0,0], [0,1,0], [0,-1,0], [0,0,1], [0,0,-1]) (0.005) true 0 true true
				subobjectLevel = 0
				
				
				-- packed section - still issues with packing code. Also, no longer works within UI
				--	if packed == true do
				--		(
				-- 		selection[i].modifiers[#unwrap_uvw].unwrap.move ()
				-- 		subobjectLevel = 3
				-- 		max select all
				-- 		selection[i].modifiers[#unwrap_uvw].pack 1 0.007 true true true
				-- 		subobjectLevel = 0
				--		modPanel.addModToSelection (TurboSmooth ()) ui:on	-- Tests to see if this block works
				--		)
				
				
				clearSelection()
			)
			select aa#() -- selects geometry which has been modified
			
		)
		
				
			
			fn copy_object obj prefix =
	( 
				
		
	if obj.category != #Editable_Objects then converttopoly obj -- fix a weird bug with unecessary faces generated on some primitives (teapot) directly converted in "editable_mesh"
	convertToMesh obj
	obj_copy = copy obj
	--copy_real=copy obj
	--copy_real.position.z =mSize.z +(20)
	 global id = obj.name
	obj_copy.name = prefix+id
	obj_copy

	)	
			infile = getDir #userScripts+"Zowee_in.fbx"
			outfile = getDir #userScripts+"Zowee_out.fbx"
			
			try (
				deletefile infile
				deletefile outfile
			)
			catch()
		undo off(
			
			temppath = getDir #userScripts + "/ZoweeScripts" + "/temp.exe"
			cmdline = "call " + "\""+ temppath +"\""+ " -i \""+infile+"\" -o \"\" -q 100 -hemiZ -width 2048 -height 2048"
			cloned_selection = for aa in selection where not aa.ishidden collect copy_object aa ""
			cloned_env = #()			
			clearSelection()
			
			
			selectmore cloned_selection
			exportfile infile #noprompt selectedOnly:true
			delete cloned_selection
			delete cloned_env
			
			HiddenDOSCommand cmdline
			
			importfile outfile #noprompt
			for aa in geometry where  aa.name == "" do
			(
				id = aa.name
			)
			
			loaded_objects = for aa in geometry where  aa.name== ""  collect aa
			delete loaded_objects
			
			select (for aa in geometry where classof aa == Editable_mesh collect aa)
			max zoomext sel
		)
enableSceneRedraw()
		
--enableSceneRedraw()
--ActionMan.executeAction 0 "40021"  -- Selection: 全选
		--sel = selection as array		
	--	
	--for i=1 to sel.count do
	--(  if  sel[i].name==id
		--then selectmore sel[i]
		--
		--
		--)
		delete aa
	)
	on btn_pressme2 pressed do 
(
	
fn uvs obj=(
aa = (for aa in selection where (isKindOf aa GeometryClass and canConvertTo aa Editable_Mesh) collect aa)
		
		-- checks to see if anything will be unwrapped, and generates error popup if not
		if aa.count == 0 then messagebox "No suitable geometry selected!"
		else
		(
			clearSelection()	-- clears selection once original selection has been saved as aa array

			for i in 1 to aa.count do	-- loops through array of suitable geometry
			(
				select aa[i]	-- selects "i"th piece of geometry
					
				-- main UVW block
				modPanel.addModToSelection (Unwrap_UVW ()) ui:on
				aa[i].modifiers[#Unwrap_UVW].unwrap.setMapChannel 3
				aa[i].modifiers[#Unwrap_UVW].unwrap.move ()
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 0
				aa[i].modifiers[#Unwrap_UVW].baseMaterial_list.count = 1
				aa[i].modifiers[#Unwrap_UVW].baseMaterial_list[1] = undefined
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 1
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 1
				aa[i].modifiers[#Unwrap_UVW].texMapList[1] = Checker ()
				aa[i].modifiers[#Unwrap_UVW].texMapIDList[1] = -1
				subobjectLevel = 3
				actionMan.executeAction 0 "40021"
				max select all
				aa[i].modifiers[#Unwrap_UVW].flattenMap 45.0 #([1,0,0], [-1,0,0], [0,1,0], [0,-1,0], [0,0,1], [0,0,-1]) (0.005) true 0 true true
				subobjectLevel = 0
				
				
				-- packed section - still issues with packing code. Also, no longer works within UI
				--	if packed == true do
				--		(
				-- 		selection[i].modifiers[#unwrap_uvw].unwrap.move ()
				-- 		subobjectLevel = 3
				-- 		max select all
				-- 		selection[i].modifiers[#unwrap_uvw].pack 1 0.007 true true true
				-- 		subobjectLevel = 0
				--		modPanel.addModToSelection (TurboSmooth ()) ui:on	-- Tests to see if this block works
				--		)
				
				
				clearSelection()
			)
			select aa#() -- selects geometry which has been modified
			
		)
	)
	uvs $
	CenterPivot $
		
for m = 1 to 24 do	
(		
		if classof $ .material != Multimaterial 
				then ($.material.glossinessMap = Bitmaptexture fileName:( maxfilePath + $.name+".png")
			    showtexturemap $.material $.material.glossinessMap on
					$.material.glossinessMap.coordinates.mappingType =0
                    $.material.glossinessMap.coordinates.mapChannel=3
				)
			else(
			
				  Mul = copy $.material
				for j = 1 to Mul.materialList.count do
				(
							Mul.materialList[j].glossinessMap=undefined
							Mul.materialList[j].glossinessMap = Bitmaptexture fileName:( maxfilePath + $.name+".png")
								showtexturemap Mul.materialList[j] Mul.materialList[j].glossinessMap on
								Mul.materialList[j].glossinessMap.coordinates.mappingType =0
                                Mul.materialList[j].glossinessMap.coordinates.mapChannel=3	
			)
			
		)
	)
macros.run "Modifier Stack" "Convert_to_Poly"
	
	)



)













rollout rollout11 "合成贴图" width:132 height:110 category:11
(    
   spinner sizecolor "贴图尺寸: " range:[0,4096,1024] type:#integer
button btn_pressme "开始烘培"
on btn_pressme pressed do(




fn uvs001 obj=(
aa = (for aa in selection where (isKindOf aa GeometryClass and canConvertTo aa Editable_Mesh) collect aa)
		
		-- checks to see if anything will be unwrapped, and generates error popup if not
		if aa.count == 0 then messagebox "No suitable geometry selected!"
		else
		(
			clearSelection()	-- clears selection once original selection has been saved as aa array

			for i in 1 to aa.count do	-- loops through array of suitable geometry
			(
				select aa[i]	-- selects "i"th piece of geometry
					
				-- main UVW block
				modPanel.addModToSelection (Unwrap_UVW ()) ui:on
				aa[i].modifiers[#Unwrap_UVW].unwrap.setMapChannel 3
				aa[i].modifiers[#Unwrap_UVW].unwrap.move ()
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 0
				aa[i].modifiers[#Unwrap_UVW].baseMaterial_list.count = 1
				aa[i].modifiers[#Unwrap_UVW].baseMaterial_list[1] = undefined
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 0
				aa[i].modifiers[#Unwrap_UVW].texMapList.count = 1
				aa[i].modifiers[#Unwrap_UVW].texMapIDList.count = 1
				aa[i].modifiers[#Unwrap_UVW].texMapList[1] = Checker ()
				aa[i].modifiers[#Unwrap_UVW].texMapIDList[1] = -1
				subobjectLevel = 3
				actionMan.executeAction 0 "40021"
				max select all
				aa[i].modifiers[#Unwrap_UVW].flattenMap 45.0 #([1,0,0], [-1,0,0], [0,1,0], [0,-1,0], [0,0,1], [0,0,-1]) (0.005) true 0 true true
				subobjectLevel = 0
				
				
				-- packed section - still issues with packing code. Also, no longer works within UI
				--	if packed == true do
				--		(
				-- 		selection[i].modifiers[#unwrap_uvw].unwrap.move ()
				-- 		subobjectLevel = 3
				-- 		max select all
				-- 		selection[i].modifiers[#unwrap_uvw].pack 1 0.007 true true true
				-- 		subobjectLevel = 0
				--		modPanel.addModToSelection (TurboSmooth ()) ui:on	-- Tests to see if this block works
				--		)
				
				
				clearSelection()
			)
			select aa#() -- selects geometry which has been modified
			
		)
	)
	uvs001 $
	





try renderers.current=Default_Scanline_Renderer() catch (messagebox "设置渲染器失败！")
mr=renderers.current
$.iNodeBakeProperties.removeAllBakeElements() 
be2 = diffusemap() -- instance of the bake element class
be2.outputSzX =be2.outputSzY = sizecolor.value --set the size of the baked map --specifythe full file path, name and type:
be2.fileType = (maxfilePath+$.name+"_ComPlete.jpg")
be2.fileName = filenameFromPath be2.fileType
be2.filterOn = true --enable filtering
be2.shadowsOn =false --enable shadows
be2.enabled = true --enable baking --Preparing theobjectfor baking:
--obj.INodeBakeProperties.addBakeElement be1 --add first element
$.INodeBakeProperties.addBakeElement be2 --add second element
$.INodeBakeProperties.bakeEnabled = true --enabling baking
$.INodeBakeProperties.bakeChannel = 3 --channel to bake
-- select obj
--$.INodeBakeProperties.nDilations = 1 --expand the texturea bit
-- mylight=Skylight castShadows:on pos:[0,0,0]
-- mylight.rays_per_sample = 20 
render rendertype:#bakeSelected vfb:off progressBar:true outputSize:[sizecolor.value ,sizecolor.value ]

                try (delete (getNodeByName "Diffuse_MT")) catch()
		DirtMaterial = StandardMaterial()
		DirtMaterial.name = "Diffuse_MT"
		Dirtmap =bitmaptexture filename:be2.fileType		
		DirtMaterial.diffusemap = Dirtmap
		DirtMaterial.selfIllumAmount = 0
		DirtMaterial.showInViewport = on
		$.Material = DirtMaterial

--bakedMat = standard diffusemap:Dirtmap
$.material = Shell_Material originalMaterial:$.material\
bakedMaterial:bakedMat viewportMtlIndex:1 renderMtlIndex:1
--showTextureMap $.material $.material.bakedMaterial true
$.material = standard diffusemap:Dirtmap 
		$.material.diffusemap.coordinates.mappingType =0
                    $.material.diffusemap.coordinates.mapChannel=3

-- delete mylight
		
		
	

macros.run "Modifier Stack" "Convert_to_Poly"
	
	showtexturemap $.material $.material.diffusemap on
		  --macros.run "Modifier Stack" "Convert_to_Poly"
		   --$.name=$.name+"1"
	  )

	  )


	  
 try(destroyDialog LitterTool01)catch()
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	  rollout LitterTool01 "材质优化" width:120 height:320 category:12
(
	local theMat, uniqueMats, mapTo, theObj
	struct aMat (theInstance, theDiffusemap)
	button youhuaMat "优化材质"  width:104 height:24

	label l_nMatIDs_t "最多ID数目:" across:2 align:#left
	label l_nMatIDs_n ""
	label l_nSubMats_t "原材质数目:" across:2 align:#left
	label l_nSubMat_n ""
	label l_nUniqueSubMats_t "现材质数目:" across:2 align:#left
	label l_nUniqueSubMat_n ""

	
	
----------------------优化材质部分-----------------------

on youhuaMat pressed do 
	(
	if selection.count ==1 do
	if classof $.material == Multimaterial then
		(
		converttomesh $
		theMat=$.material 
		l_nSubMat_n.text=theMat.numsubs as string
		local SubMatUsed=#()
		for f=1 to $.numfaces do
			SubMatUsed[getFaceMatID $ f]=true
		    l_nMatIDs_n.text=SubMatUsed.count as string
		    uniqueMats=#()
		    mapTo=#()
		for m=1 to theMat.numsubs do
			(
			if SubMatUsed[m] != true do continue
			local thisMatDBitmap=undefined
			if classof theMat[m] == StandardMaterial do
				if classof theMat[m].diffusemap == Bitmaptexture do
					thisMatDBitmap=theMat[m].diffusemap.filename
			if thisMatDBitmap == undefined do
			(	append uniqueMats (aMat theMat[m] thisMatDBitmap)
				mapTo[m]=uniqueMats.count
				continue
			)
			local foundMatch=false
			for p=1 to uniqueMats.count do
				if thisMatDBitmap == uniqueMats[p].theDiffusemap do
				(	mapTo[m]=p
					foundMatch=true
					continue
				)
			if not foundMatch do 
			(	append uniqueMats (aMat theMat[m] thisMatDBitmap)
				mapTo[m]=uniqueMats.count
			)
		)			
		l_nUniqueSubMat_n.text=uniqueMats.count as string
		local NewMMat=Multimaterial numsubs:uniqueMats.count name:($.name+"_"+$.material.name)
		for m=1 to uniqueMats.count do
			NewMMat[m]=copy uniqueMats[m].theInstance
		for f=1 to $.numfaces do
			(
			local oldID=getFaceMatID $ f
			setFaceMatID $ f mapTo[oldID]
			)
		$.material=NewMMat
		update $
		meditMaterials[1]=$.material
	   	a=meditMaterials[1].materialIDList
		for i = 1 to a.count do 
			(
			showTextureMap meditMaterials[1].materialList[a[i]] on
			)	
		converttopoly $
		)
	else messagebox "不是多维材质"	
	) 			

on youhuaMat2 pressed do 
	(
	if selection.count != 0 do
		for a = 1 to selection.count do
		(			---------------------------------------------------------括号02
		pro2.value = 100.0 * a / selection.count
		if classof selection[a].material == Multimaterial do 
			(
			converttomesh selection
			theMat=selection[a].material 		
			local SubMatUsed=#()
			for f=1 to selection[a].numfaces do
				SubMatUsed[getFaceMatID selection[a] f]=true
			    uniqueMats=#()
			    mapTo=#()
			for m=1 to theMat.numsubs do
			(	if SubMatUsed[m] != true do continue
				local thisMatDBitmap=undefined
				if classof theMat[m] == StandardMaterial do
					if classof theMat[m].diffusemap == Bitmaptexture do
						thisMatDBitmap=theMat[m].diffusemap.filename
				if thisMatDBitmap == undefined do
				(	append uniqueMats (aMat theMat[m] thisMatDBitmap)
					mapTo[m]=uniqueMats.count
					continue
				)
				local foundMatch=false
				for p=1 to uniqueMats.count do
					if thisMatDBitmap == uniqueMats[p].theDiffusemap do
					(	mapTo[m]=p
						foundMatch=true
						continue
					)
				if not foundMatch do 
				(	append uniqueMats (aMat theMat[m] thisMatDBitmap)
					mapTo[m]=uniqueMats.count
				)
			)
			
		
	     	local NewMMat=Multimaterial numsubs:uniqueMats.count name:(selection[a].name+"_"+selection[a].material.name)
			for m=1 to uniqueMats.count do
				NewMMat[m]=copy uniqueMats[m].theInstance
			for f=1 to selection[a].numfaces do
			(	local oldID=getFaceMatID selection[a] f
				setFaceMatID selection[a] f mapTo[oldID]
			)
			selection[a].material=NewMMat
			update selection[a]
			meditMaterials[1]=selection[a].material
		   	     a=meditMaterials[1].materialIDList
				 for i = 1 to a.count do 
					(
					showTextureMap meditMaterials[1].materialList[a[i]] on
					)	
		converttopoly selection
			)	
	)
	)				


)



----------------------





------------------------进度条------------------------

------------------------工具箱------------------------
rollout ToolsPackage "常用工具"
(
	button ClearEmptyActor "清理空物体" 
	button SetPivotToCenter "归轴至中心" across:2
	button SetPivotToButtom "归轴至底部"
	button SetPivotToTop "归轴至顶部" across:2
	button SetPivotWorldZero "归轴至原点"
	button OnekeyXform "一键重置变换"
	
	on OnekeyXform pressed do
	(
	)	
	
	on SetPivotWorldZero pressed do
	(
		for objs in selection do
		(
			objs.pivot=[0,0,0]
		)
	)
	
	on ClearEmptyActor pressed do
	(
		clearselection()
		local Convertcount=0
		for objs in $* do
		(
			try
			(
				if objs.getnumfaces() == 0 then
				(
					selectmore objs
					Convertcount+=1
				)
			)
			catch
			(
				try
				(
					convertToPoly(objs)
					if objs.getnumfaces() == 0 then 
					(
						selectmore objs
						Convertcount+=1
					)
				)
				catch
				(
				)
			)
		)
		try(delete $)
		catch()
		Messagebox ("共删除" + (Convertcount as string) + "个空物体")
	)
	
	on SetPivotToCenter pressed do
	(
		for objs in selection do
		(
			centerpivot(objs)
		)
	)
	
	on SetPivotToButtom pressed do
	(
		for objs in selection do 
		(
			converttopoly(objs)
			local AllVertCount=objs.getnumvertices()
			local LowestVertZAxis = 0 
			try
			(
				converttomesh(objs)
				LowestVertZAxis = (getVert objs 1).z
				local VertIndex = 1
				while VertIndex <= AllVertCount do
				(
					if (getVert objs VertIndex).z <= LowestVertZAxis then
					(
						LowestVertZAxis = (getVert objs VertIndex).z
					)
					else()
					VertIndex+=1
				)
				centerpivot(objs)
				objs.pivot.z = LowestVertZAxis
			)
			catch()
		)
	)
	
	on SetPivotToTop pressed do
	(
		for objs in selection do 
		(
			converttopoly(objs)
			local AllVertCount=objs.getnumvertices()
			local MostHighVertZAxis = 0 
			try 
			(
				converttomesh(objs)
				MostHighVertZAxis = (getVert objs 1).z
				local VertIndex = 1
				while VertIndex <= AllVertCount do
				(
					if (getVert objs VertIndex).z >= MostHighVertZAxis then
					(
						MostHighVertZAxis = (getVert objs VertIndex).z
					)
					else()
					VertIndex+=1
				)
				centerpivot(objs)
				objs.pivot.z = MostHighVertZAxis
			)
			catch()
		)
	)
)
	
	
-----------------批量导入----------------------
	
	rollout roll_import "批量导入\合并"
(
	local objfiles=#()
	local _3dsfiles=#()
	local allfiles=#()
	local FBXfiles=#()
	local maxfiles=#()
	local DWGfiles=#()
	local filetpye=#()
	local allfilesfull=#()
	
	
	multilistbox mlbox_files "文件列表：" items:#() selection:0 height:15 readOnly:off  width:450 align:#center
	button btn_path "选择路径" width:80 height:40 align:#left across:4
	radiobuttons rbtn_tpye "导入\合并文件类型：" labels:#("OBJ","3DS","FBX","DWG","MAX","ALL") default:6 columns:6  align:#center offset:[70,3]
	checkbox mulu "包含子文件夹" align:#right offset:[120,3] checked:on
	button shuaxin "刷新"  width:60 align:#right offset:[0,20]
	button btn_import "开始导入" width:450 height:40 align:#center

	fn getFilesRecursive root pattern =
	(
		dir_array = GetDirectories (root+"/*")
		for d in dir_array do
		join dir_array (GetDirectories (d+"/*"))
		
		my_files = #()
		for f in dir_array do
		join my_files (getFiles (f + pattern))
		join my_files (getFiles (root+"\\"+pattern))
		my_files 
	)
	--get all .ms files from the max installation
	--allfiles=getFilesRecursive "e:/www" "*.max"
	
	on btn_path pressed do 
	(
		objfiles=#()
		_3dsfiles=#()
		allfiles=#()
		FBXfiles=#()
		DWGfiles=#()
		maxfiles=#()
		filetpye=#()
		allfilesfull=#()
		
		importpath=(getSavePath caption:"选择导入文件的的路径" initialDir:maxfilepath)
		if importpath!=undefined do 
		(			
			objfiles = (if mulu.checked then  ( getFilesRecursive importpath "*.obj") else (getfiles (importpath+"\\*.obj")))
			_3dsfiles = (if mulu.checked then ( getFilesRecursive importpath "*.3ds") else (getfiles (importpath+"\\*.3ds")))
			FBXfiles = (if mulu.checked then ( getFilesRecursive importpath "*.FBX") else (getfiles (importpath+"\\*.FBX")))
			DWGfiles = (if mulu.checked then ( getFilesRecursive importpath "*.dwg") else (getfiles (importpath+"\\*.dwg")))
			maxfiles = (if mulu.checked then ( getFilesRecursive importpath "*.max") else (getfiles (importpath+"\\*.max")))
		)--end if i....
		for i in objfiles do (append filetpye "obj";append allfiles ((filenameFromPath i) +"     ["+(getFilenamePath i) +"]");append allfilesfull i;) 
		for i in _3dsfiles do (append filetpye "3ds";append allfiles ((filenameFromPath i) +"     ["+(getFilenamePath i) +"]");append allfilesfull i;) 
		for i in FBXfiles do (append filetpye "FBX";append allfiles ((filenameFromPath i) +"     ["+(getFilenamePath i) +"]");append allfilesfull i;) 
		for i in DWGfiles do (append filetpye "dwg";append allfiles ((filenameFromPath i) +"     ["+(getFilenamePath i) +"]");append allfilesfull i;)
		for i in maxfiles do (append filetpye "max";append allfiles ((filenameFromPath i) +"     ["+(getFilenamePath i) +"]");append allfilesfull i;)
		mlbox_files.items=allfiles
		mlbox_files.selection = (for i = 1 to allfiles.count collect i) as bitarray
		rbtn_tpye.state=6		
	)--end on
	
	on  rbtn_tpye changed val do 
	(
		case val of 
		(
			1:(newfiles=#();for i in 1 to filetpye.count do (if filetpye[i]=="obj" do append newfiles allfiles[i]);mlbox_files.items=newfiles;mlbox_files.selection=#{1..newfiles.count})
			2:(newfiles=#();for i in 1 to filetpye.count do (if filetpye[i]=="3ds" do append newfiles allfiles[i]);mlbox_files.items=newfiles;mlbox_files.selection=#{1..newfiles.count})
			3:(newfiles=#();for i in 1 to filetpye.count do (if filetpye[i]=="FBX" do append newfiles allfiles[i]);mlbox_files.items=newfiles;mlbox_files.selection=#{1..newfiles.count})
			4:(newfiles=#();for i in 1 to filetpye.count do (if filetpye[i]=="dwg" do append newfiles allfiles[i]);mlbox_files.items=newfiles;mlbox_files.selection=#{1..newfiles.count})
			5:(newfiles=#();for i in 1 to filetpye.count do (if filetpye[i]=="max" do append newfiles allfiles[i]);mlbox_files.items=newfiles;mlbox_files.selection=#{1..newfiles.count})
			6:(mlbox_files.items=allfiles;mlbox_files.selection=#{1..allfiles.count})
			default:()
		)
	)--end  on....

	on btn_import pressed do
	(
		importfiles=#()
		thesel=mlbox_files.selection
		for i in thesel do
		(
			a=mlbox_files.items[i]
			b=(finditem allfiles a)
			if b!=0 do append importfiles allfilesfull[b]
		)--end for i...
		if importfiles.count!=0 do 
		(
			for i in importfiles do 
			(
				if (getFilenameType i !=".max")
				then (importFile i  #noPrompt)
				else (mergeMAXFile i #noRedraw  #mergeDups #renameMtlDups )
			)--end for
		)--end if
		
	)--end on btn_import ...
	
)
	
-----------------------------创建ue4样条线数据



------------------------------	创建文件		

	 	 

Rollout maxsplineData "创建UE4样条线数据集"
	(
		
		group "MAX样条线数据导出设置"
		(	label label1 "选择UE4工程Content路径:" align:#left
			edittext UE4_ExportPath_Text readonly:true height:24 width:280 align:#left across:3
			button UE4_SetExportPathButton "导出路径"  height:24 width:80 offset:[100,0] tooltip:"选择导出路径"
			button UE4_ClearExportPathButton "清楚路径"  height:24 width:60 offset:[50,0] tooltip:"重置导出路径到此MAX文件目录"
		)

	button btnData "开始创建数据" 
		
	fn CreateSplineData  DataIndex Obj=

(	
	if((numSplines Obj)==2)then
		
	(


	--makeDir @"C:/CSV"  all:true
	  cmd="md MaxSplineCSVFile2"

      HiddenDOSCommand cmd startpath:UE4_ExportPath_Text.text
	arrstring=filterString maxFileName "."
	if(maxFileName!="")then
	(
		timeNow=filterString localTime "/,:, "
		timestring=timeNow[1] as string+timeNow[2] as string+timeNow[3] as string+timeNow[4] as string+timeNow[5] as string+timeNow[6] as string
		
		out_file = createfile (UE4_ExportPath_Text.text+"/MaxSplineCSVFile2/SplineData"+"_"+arrstring[1]+"_"+timestring+"_00"+DataIndex as string+".csv")
		
		)
		else
		
		(
			timeNow=filterString localTime "/,:, "
		    timestring=timeNow[1] as string+timeNow[2] as string+timeNow[3] as string+timeNow[4] as string+timeNow[5] as string+timeNow[6] as string
-- 			makeDir @"C:/Users/yubo/Desktop/CSV"  all:true
		    out_file = createfile (UE4_ExportPath_Text.text+"/MaxSplineCSVFile2/SplineData"+"_"+"undefined"+"_"+timestring+"_00"+DataIndex as string+".csv")
			)
			
			startName="NumId,Vert_X,Vert_Y,Vert_Z,InVert_X,InVert_Y,Invert_Z,OutVert_X,OutVert_Y,OutVert_Z,"as string
			Spine_1="Vert_X_1,Vert_Y_1,Vert_Z_1,InVert_X_1,InVert_Y_1,Invert_Z_1,OutVert_X_1,OutVert_Y_1,OutVert_Z_1,"as string
			Spine_2="Vert_X_2,Vert_Y_2,Vert_Z_2,InVert_X_2,InVert_Y_2,Invert_Z_2,OutVert_X_2,OutVert_Y_2,OutVert_Z_2,"as string
			format startName  to:out_file	
			format Spine_1  to:out_file
			format Spine_2  to:out_file
			format "DV_X,DV_Y,DV_Z"to:out_file
			format "\n" to:out_file 
------------------------------	创建文件	

------------------------------收集点数据	
       ---焊接顶点
	    thespline=convertToSplineShape Obj
		select Obj
		macros.run "Modifier Stack" "SubObject_1"
		actionMan.executeAction 0 "40021"
		max select all
		macros.run "Editable Spline Object" "ESpline_Weld"
       ---焊接顶点

			
				
				v1=getKnotPoint Obj 1 1
			    v2=getKnotPoint Obj 2 1
			
			
			deltPos=(v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y)+(v1.z-v2.z)*(v1.z-v2.z)
			
-- 			print "两点距离"
-- 			print deltPos
			deltPos=sqrt deltPos
			
-- 			print "两点距离"
-- 			print deltPos
			if(deltPos>5000)then 
			(reverse thespline 1
				)
			
			
			
			 choiceCount=numKnots thespline 1
			--取得方向
			 
				

				
				


				
-- 



---全局变量
	
          arrVects_1=#()
		  arrVecIn_1=#()
		  arrVecOut_1=#()
		  arrVects_2=#()
		  arrVecIn_2=#()
		  arrVecOut_2=#()
		  arrVects=#()
	      arrVecIn=#()
	      arrVecOut=#()	
		  arrDiectionV=#()
--第一条样条线数据
		 
		for v = 1 to  numKnots Obj 1 do
		(
			
			vertPos=getKnotPoint Obj 1 v--点位信息
			
			vertIn=getInvec Obj 1 v--进入切线位置
			vertOut=getOutvec Obj 1 v--出去切线位置
			
			append  arrVects_1 vertPos  
			append   arrVecIn_1 vertIn 
			append   arrVecOut_1 vertOut 
		 
			)

--第二条样条线数据
			
		 


		for v = 1 to  numKnots Obj 2 do
		(
			
			vertPos=getKnotPoint Obj 2 v--点位信息
			
			vertIn=getInvec Obj 2 v--进入切线位置
			vertOut=getOutvec Obj 2 v--出去切线位置
			
			append   arrVects_2 vertPos  
			append   arrVecIn_2 vertIn 
			append   arrVecOut_2 vertOut 
		 
			)
-- print "==============="
	
			lastCout=0
      if (arrVects_2.count>arrVects_1.count	)then
			(
				lastCout=arrVects_1.count
				)else
				(
					lastCout=arrVects_2.count
					)
				
			
	

-- print "==============="			
			
	 
        for i = 1 to lastCout do
		(

			vert_X=(arrVects_1[i].x+arrVects_2[i].x)/2
			vert_Y=(arrVects_1[i].y+arrVects_2[i].y)/2
			vert_Z=(arrVects_1[i].z+arrVects_2[i].z)/2
			
			vertIn_X=(arrVecIn_1[i].x+arrVecIn_2[i].x)/2
			vertIn_Y=(arrVecIn_1[i].y+arrVecIn_2[i].y)/2
			vertIn_Z=(arrVecIn_1[i].z+arrVecIn_2[i].z)/2
			
			vertOut_X=(arrVecOut_1[i].x+arrVecOut_2[i].x)/2
			vertOut_Y=(arrVecOut_1[i].y+arrVecOut_2[i].y)/2
			vertOut_Z=(arrVecOut_1[i].z+arrVecOut_2[i].z)/2
			
		    DV_X=arrVects_1[i].x-arrVects_2[i].x
			DV_Y=arrVects_1[i].y-arrVects_2[i].y
			DV_Z=arrVects_1[i].z-arrVects_2[i].z
		
			vertNew=[vert_X,vert_Y,vert_Z]

			vertDir=[DV_X,DV_Y,DV_Z]	
				
				
			
			--测试正序还是反序
			
			
-- 			vertDebug=[arrVects_2[i].x,arrVects_2[i].y,0]
-- 			newTag=Sphere()
-- 			newTag.pos=vertDebug
-- 			newTag.radius=100
-- 			newTag.scale=[1*i,1*i,1*i]
			
			vert_InNew=[vertIn_X,vertIn_Y,vertIn_Z]
			
			vert_OutNew=[vertOut_X,vertOut_Y,vertOut_Z]

			append  arrVects vertNew  
			append  arrVecIn vert_InNew  
			append  arrVecOut vert_OutNew  
			
			append  arrDiectionV vertDir  

		

		)
	

----------单条线的数据收集可以用下面注释掉的内容
-- 		for v = 1 to  numKnots $ 1 do
-- 		(
-- 			
-- 			vertPos=getKnotPoint $ 1 v--点位信息
-- 			
-- 			vertIn=getInvec $ 1 v--进入切线位置
-- 			vertOut=getOutvec $ 1 v--出去切线位置
-- 			
-- 			append  arrVects vertPos  
-- 			append   arrVecIn vertIn 
-- 			append   arrVecOut vertOut 
-- 		 
-- 			)
------------------------------收集点数据	

		
		
		
		
------------------------------写入数据	

	

		for i = 1 to  choiceCount  do
			( 
				----中心线数据
				
				format "%,"  (i-1)  to:out_file
				format "%," arrVects[i].x to:out_file
				format "%," arrVects[i].y to:out_file
				format "%," arrVects[i].z to:out_file
				
				
				
				format "%," arrVecIn[i].x to:out_file
				format "%," arrVecIn[i].y to:out_file
				format "%," arrVecIn[i].z to:out_file
				
				format "%," arrVecOut[i].x to:out_file
				format "%," arrVecOut[i].y to:out_file
				format "%,"  arrVecOut[i].z to:out_file
			-----第一根边线数据	
				
				format "%," arrVects_1[i].x to:out_file
				format "%," arrVects_1[i].y to:out_file
				format "%," arrVects_1[i].z to:out_file
				
				
				
				format "%," arrVecIn_1[i].x to:out_file
				format "%," arrVecIn_1[i].y to:out_file
				format "%," arrVecIn_1[i].z to:out_file
				
				format "%," arrVecOut_1[i].x to:out_file
				format "%," arrVecOut_1[i].y to:out_file
				format "%,"  arrVecOut_1[i].z to:out_file
				-----第二根边线数据
				format "%," arrVects_2[i].x to:out_file
				format "%," arrVects_2[i].y to:out_file
				format "%," arrVects_2[i].z to:out_file
				
				
				
				format "%," arrVecIn_2[i].x to:out_file
				format "%," arrVecIn_2[i].y to:out_file
				format "%," arrVecIn_2[i].z to:out_file
				
				format "%," arrVecOut_2[i].x to:out_file
				format "%," arrVecOut_2[i].y to:out_file
				format "%," arrVecOut_2[i].z to:out_file

				
				
				format "%," arrDiectionV[i].x to:out_file
				format "%," arrDiectionV[i].y to:out_file
				format "%"  arrDiectionV[i].z to:out_file
				
				format "\n" to:out_file 
				
				
	        )
			
			    
			close out_file
			
				)
				else (
				msg="样条线个数不为2 物体："+Obj.name
					messagebox msg
					)
            
			

			
			
			
	
	

	)	
		
    fn updateExportPath =
		(
			-- If exportPath AND maxFilePath aren't set
			if maxfilepath == "" and ExportPath == undefined then 
				UE4_ExportPath_Text.text = "Please save the scene or specify an export path explicitly."
			
			-- If exportPath has NOT been defined and the scene file HAS been saved, assume the export path
			if exportPath == undefined and maxfilepath != "" do 
			(
				--exportPath = maxfilepath+@"export\"
				
				UE4_ExportPath_Text.text = ""
			)
				
			--If there's an export path defined in the scene, use that instead
			SavedExportPath = (getAppData rootNode 77900)
			if (SavedExportPath != undefined) then 
			(
				exportPath = SavedExportPath
				UE4_ExportPath_Text.text = exportPath
			) 
		)		
    on UE4_SetExportPathButton pressed do                                                    
		(
			--Open to a resonable location
			if (doesfileexist (exportPath as String)) then thePath = getSavepath initialDir:(exportPath)
			else thePath = getSavepath initialDir:(maxfilepath)
			print thePath
			
			--Once set, save the path to the scene's appdata
			if thePath != undefined then 
			(
				exportPath = thePath
				SetAppData rootNode 77900 exportPath
			)
				
			--updateList()
			updateExportPath()
		)
		
		on UE4_ClearExportPathButton pressed do
		(
			exportPath = undefined
			deleteAppData rootNode 77900
			--updateList()
			updateExportPath()
		)	

     on OpenExportPathButton pressed do
		(
			if exportPath != undefined then
				if (checkExportPath exportPath == true) then shellLaunch "explorer.exe" exportPath
			else 
				messageBox "No export path is defined."
		)
		
	on btnData pressed do
		(
			
		pathnameNew=UE4_ExportPath_Text.text+"/MaxSplineCSVFile/SplineData/*.csv"
	    myfiles=getFiles pathnameNew

		for i=1 to myfiles.count do
		(
		deleteFile myfiles[i]
		)		
	sel=selection as array
			
			
			
	
	if(sel.count<1)then
	
	  (
		  messagebox "请选择道路样条线"
		
		)
		
		
	
	for a=1 to sel.count do
	(    
        if(classof sel[a]==line or classof sel[a]==SplineShape )then
		(sel[a].name="Spline" +"00"+a as string)
		
		else
		(
			messagebox "请不要选择非样条线物体"
			
			)
		
	    
    
	)
		
		
	for i=1 to sel.count do
	      (
			  
			  
		if(classof sel[i]==line or classof sel[i]==SplineShape )then
		(
			CreateSplineData i sel[i] 
			)
		
		else
		(
			print sel[i].name
			
			)	  
		
		  )
		  
		)

		)




	
	
	
	
	
	
	
	
	
	
	
	
	
	

------------------------MAC加密-------------------------
	
global AllowList=#("3497F652B2B8","408D5C84F2D7","408D5C871780")
global IsAllowToUse=false
fn fl_getMacAddressByDotNet01 = (
     --Get mac address,by feilang
    local dt = (dotNetClass "System.Net.NetworkInformation.NetworkInterface").GetAllNetworkInterfaces()
    for i in dt do
    (    tempAdd=(i.GetPhysicalAddress()).ToString()
        if tempAdd != "" then return tempAdd
    )
    ""
)
YourMacAddr=fl_getmacaddressbydotnet01()

if YourMacAddr == "3497F652B2B8" then ( IsAllowToUse = true )
IsAllowToUse = true
-------------------------绘制窗口------------------------
if IsAllowToUse == true then
(
	theFloater = newRolloutfloater "51VR·虚幻4资源自动转换工具 Version 0.2" 500 1000
	
	
	
	addrollout VrayConvertToScanline theFloater rolledup:true
	addrollout roll_acciones theFloater rolledup:true
	addrollout AlphoeniXTool theFloater rolledup:true
	addrollout UE4_Export_FBX_Rollout theFloater rolledup:true
	addrollout ToolsPackage theFloater rolledup:true
	addrollout rollout01 theFloater rolledup:true
	addrollout rollout08 theFloater rolledup:true
	addrollout rollout10 theFloater rolledup:true
	addrollout rollout11 theFloater rolledup:true
	
	addrollout roll_import theFloater rolledup:true
	
	addrollout LitterTool01 theFloater rolledup:true
                addrollout maxsplineData theFloater rolledup:true
	
	
	
	
	addrollout Documentation theFloater
)
else
(
	messagebox ("您的计算机没有权限使用此插件，将以下字段提供给开发者以打开权限： " + YourMacAddr)
)

