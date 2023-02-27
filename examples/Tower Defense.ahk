;Basic tower defense example by Spawnova (2/25/2023)
;Written as a basic example for my game class - https://github.com/Spawnova/ShinsGameClass
;
;This is a very basic example, it's not a full game but more of a demo of how you can use
;my class to build stuff

;This is a project just for fun and it has both design flaws and inneficient code
;but I had fun writing it so I don't care =)


;If I get motivation maybe i will update later with more stuff

;Sorry for lack of comments, I'm not very good at it and i rarely do it as a hobbyist






;#include <ShinsGameClass>  ;if the class if in your library folder you can use this
;#include ShinsGameClass.ahk ;if the class is in your working directory you can use this
#include ../ShinsGameClass.ahk ;if you downloaded the github then this should work

setbatchlines,-1 ;this is necessary for vsync to work

vsync := 1 ;turn to 0 to see how fast it can run =P
game := new ShinsGameClass(0,0,1000,800,"Tower Defense by Spawnova",vsync)
game.interpolationMode := 0

gosub setupPath ;setup path nodes

; Create spawner class, handles the enemy spawning and wave stuff
; Waves are added using AddSpawn function, the string contains the wave data
; data is seperated by pipe, an element with 1 value is a delay
; and an element with 3 values is the spawn info COUNT,ENEMY_ID,DELAY
game.data.spawner := new spawnerClass(game)
game.data.spawner.AddSpawn(1,"10,0,1")
game.data.spawner.AddSpawn(2,"15,0,1|2|3,1,0.55")
game.data.spawner.AddSpawn(3,"5,1,0.1|5,0,0.55|1|15,0,0.1")
game.data.spawner.AddSpawn(4,"10,1,0.2|1|15,1,0.05|2|30,0,0.1")
game.data.spawner.AddSpawn(5,"20,0,0.05|1|20,0,0.05|1|20,0,0.05|1|20,1,0.1|1|100,0,0.1")
game.data.spawner.AddSpawn(6,"200,0,0.02|2|50,1,0.02")


; some generic variables
game.data.lives := 42
game.data.money := 500
game.data.running := 0
game.data.hoverText := 0



; Setup buy towers, 3rd param = 0 means it's inactive and functions as a buy tower
game.data.towers := []
game.data.towers.push(new tower1Class(game,820,300,0))
game.data.towers.push(new tower2Class(game,920,300,0))
game.data.towers.push(new tower3Class(game,820,400,0))


; Setup enemies
game.data.enemies := []

; Create a path guide to show enemy path
game.data.pathGuide := new pathGuideClass(game)

; Create a placement marker for placing towers
game.data.placeMarker := new placeMarkerClass(game)

game.data.speedControl := new speedControlClass(game,800-138,800-74)

game.data.particles := []
game.data.projectiles := []

loop {
	if (game.BeginDraw()) {
		
		ProcessFrame(game)
		
		game.EndDraw()
	} else {
		sleep 50
	}
}
exitapp


f9::Reload
f8::Exitapp

#ifwinactive Tower Defense by Spawnova

space::
if (!game.data.running)
	game.data.spawner.StartWave(0)
return

#if






;process frame data by updating all objects
ProcessFrame(game) {

	;enemies[1].x := game.mouseX-16
	;enemies[1].y := game.mouseY-16
	
	game.DrawImage("resources\images\back.png",0,0,800,800) ;draw background
	game.DrawImage("resources\images\panel.png",800,0,200,800) ;draw panel on the side
	
	game.data.SpeedControl.Update()
	
	;show the pathing arrow if not running
	game.data.pathGuide.Update()
	
	;handle spawning enemies and waves
	game.data.spawner.Update()
	
	
	;if hovering over a tower replace text with tower details (in the tower update function)
	if (!game.data.hoverText)
		game.DrawText("Hover towers for info`n`nClick towers to place`n`nRight click to cancel",800,20,20,0xFFFFA200,"Arial","acenter w" 200)
	game.data.hoverText := 0
	
	;for placing towers
	game.data.placeMarker.update()
	
	
	;update towers backwards so buy towers are on top
	towerLen := game.data.towers.length()
	loop % towerLen
		game.data.towers[towerLen-(a_index-1)].Update()
		
		
	for k,v in game.data.projectiles
		v.Update()
		
	
	;update enemies in backwards direction, so the first spawns appear over the newer ones
	enemyLen := game.data.enemies.length()
	loop % enemyLen
		game.data.enemies[enemyLen-(a_index-1)].Update()
	loop % enemyLen
		game.data.enemies[enemyLen-(a_index-1)].DrawHealthBar() ;do healthbars seperately so they are over all enemies
	
	
	for k,v in game.data.particles
		v.Update()
	
	
	game.DrawText("Wave " game.data.spawner.waveIndex "/" game.data.spawner.waveMax "  -  Lives " game.data.lives "  -  Monies " game.data.money,0,0,28,0xFFF9F214,"Arial","olFF000000 acenter w" 800)
	game.DrawText("FPS: " game.fps,810,770,20)
	if (game.data.lives <= 0) {
		game.gameSpeed := 0
		game.DrawText("GAME OVER",0,300,80,0xFFFF0000,"Arial","olFF000000 acenter w" 800)
		game.DrawText("F8: Exit`nF9: Reload",0,500,60,0xFFFFFFFF,"Arial","olFF000000 acenter w" 800)
	} else if (game.data.spawner.waveIndex = game.data.spawner.waveMax+1) {
		game.gameSpeed := 0
		game.DrawText("A WINNER IS YOU!",0,300,80,0xFF00FF00,"Arial","olFF000000 acenter w" 800)
		game.DrawText("F8: Exit`nF9: Reload",0,500,60,0xFFFFFFFF,"Arial","olFF000000 acenter w" 800)
	}
	
	;handle cleanup
	PurgeInactive(game.data.enemies)
	PurgeInactive(game.data.projectiles)
	PurgeInactive(game.data.particles)
	
	return
}


;removes inactive elements in an array
PurgeInactive(a) {
	loop {
		done := true
		for k,v in a
		{
			if (!v.active) {
				a.removeat(k)
				done := false
				break
			}
		}
		if (done)
			break
	}
}

class speedControlClass {
	__New(game,x,y) {
		this.game := game
		this.x := x
		this.y := y
		this.hover := 0
		this.speed := 1
		this.img := "resources\images\speed1.png"
	}
	
	Update() {
		this.hover := 0
		if (this.game.MouseInRegion(this.x,this.y,this.x+128,this.y+64)) {
			this.hover := 1
			if (this.game.lbutton) {
				this.speed++
				if (this.speed > 3)
					this.speed := 1
				this.game.gameSpeed := this.speed
				this.img := "resources\images\speed" this.speed ".png"
			}
		}
		this.Draw()
	}
	
	Draw() {
		this.game.drawImage(this.img,this.x,this.y,128,64,0,0,0,0,(this.hover?1:0.5))
	}
}

;some of these i havent implemented
class particleClass {
	__New(game,x,y) {
		this.x := x
		this.y := y
		this.game := game
		this.img := ""
		this.frameSpeed := 0
		this.frameSpeedDelay := 0
		this.frame := 1
		this.frames := 1
		this.rotation := 0
		this.rotationInc := 0
		this.rotationSpeed := 0
		this.rotationSpeedDelay := 0
		this.rotationOffsetX := 0
		this.rotationOffsetY := 0
		this.lifeSpan := 5
		this.scaleX := 1
		this.scaleY := 1
		this.scaleInc := 0
		this.scaleSpeed := 0
		this.scaleSpeedDelay := 0
		this.alpha := 1
		this.alphaInc := 0
		this.alphaSpeed := 0
		this.alphaSpeedDelay := 0
		this.drawCenter := 1
		this.speed := 0
		this.direction := 0
		this.gravity := 0
		this.friction := 0
		this.active := 1
		this.w := 1
		this.h := 1
	}
	
	SetImage(img) {
		this.game.GetImageDimensions(img,w,h)
		this.w := w
		this.h := h
		this.img := img
	}
	
	Update() {

		if (!this.active)
			return
		if (this.frames > 1) {
		
		}
		if	(this.speed != 0) {
			this.x += (this.speed * -cos(this.direction)) * this.game.timeScale
			this.y += (this.speed * -sin(this.direction)) * this.game.timeScale
		}
		if (this.rotationInc != 0) {
			this.rotation += this.rotationInc * this.game.timeScale
			if (this.rotation > 359)
				this.rotation -= 360
		}
		if (this.scaleInc != 0) {
			this.scaleX += this.scaleInc * this.game.timeScale
			this.scaleY += this.scaleInc * this.game.timeScale
			if (this.scaleX <= 0 or this.scaleY <= 0)
				this.active := 0
		}
		if (this.alphaInc != 0) {
			this.alpha += this.alphaInc * this.game.timeScale
			if (this.alpha <= 0)
				this.active := 0
			this.alpha := (this.alpha > 1 ? 1 : this.alpha)
		}
		
		
		this.lifespan -= this.game.timeScale
		if (this.lifespan <= 0)
			this.active := 0
		if (this.active)
			this.Draw()
	}
	
	Draw() {
		w := this.w * this.scaleX
		h := this.h * this.scaleY
		this.game.drawimage(this.img,this.x,this.y,w,h,0,0,0,0,this.alpha,this.drawCenter,this.rotation,this.rotationOffsetX,this.rotationOffsetY)
	}
}

class projectileClass {
	__New(game,x,y,img) {
		this.x := x
		this.y := y
		this.game := game
		this.img := img
		this.range := 8
		this.active := 1
		this.speed := 1
		this.damage := 1
		this.direction := 1
		this.lifeSpan := 999
		this.homing := 0
		this.targetX := 0
		this.targetY := 0
		this.rotation := 0
		this.angleRad := 0
	}
	
	SetTargetPosition(x,y) {
		this.targetx := x-this.x
		this.targety := y-this.y
		this.homing := 0
	}
	SetTargetAngle(angleRad,setRotation:=0) {
		this.targetx := this.speed * -cos(angleRad)
		this.targety := this.speed * -sin(angleRad)
		this.homing := 0
		this.angleRad := angleRad
		if (setRotation) {
			this.rotation := angleRad*57.295779
		}
	}
	
	Update() {

		if (!this.active)
			return
		
		this.lifespan -= this.game.timeScale
		if (this.lifespan <= 0)
			this.active := 0
		
		this.x += (this.targetx * this.game.timeScale)
		this.y += (this.targety * this.game.timeScale)
		
		if (this.x < -30 or this.y < -30 or this.x > 1030 or this.y > 830)
			this.active := 0
		
		for k,v in this.game.data.enemies
		{
			
			if (v.active and v.health > 0 and this.EnemyInRange(v,dist)) {
				v.health -= this.damage
				if (this.img = "resources\images\proj1.png") {
					ps := 5
					loop % ps {
						part := new particleClass(this.game,this.x+random(-4,4),this.y+random(-4,4))
						part.SetImage("resources\images\hit.png")
						part.scaleX := part.scaleY := random(2.5,4.2)
						part.direction := this.angleRad + random(-0.3,0.3)
						part.speed := random(60,120)
						part.rotation := random(0,359)
						part.rotationInc := random(-500,500)
						part.alphaInc := random(-7,-3)
						this.game.data.particles.push(part)
					}
				} else {
					part := new particleClass(this.game,this.x,this.y)
					part.SetImage("resources\images\hit.png")
					part.scaleX := part.scaleY := random(2.5,4.2)
					part.direction := this.angleRad + random(-0.3,0.3)
					part.speed := random(60,120)
					part.rotation := random(0,359)
					part.rotationInc := random(-500,500)
					part.alphaInc := random(-7,-3)
					this.game.data.particles.push(part)
				}
				
				this.active := 0
				return
			}
		}
		
		if (this.active)
			this.Draw()
	}
	
	EnemyInRange(enemy,byref dist) {
		dx := this.x - enemy.x
		dy := this.y - enemy.y
		dist := sqrt(dx*dx + dy*dy)
		return (dist < (this.range + enemy.colSize))
	}
	
	Draw() {
		this.game.drawimage(this.img,this.x,this.y,16,16,0,0,0,0,1,1,this.rotation)
	}
}

class spawnerClass {
	__New(game) {
		this.game := game
		this.spawns := []
		this.waveIndex := 1
		this.waveMax := 0
	}
	
	
	AddSpawn(index,data) {
		this.spawns[index] := []
		s := strsplit(data,"|")
		for k,v in s
		{
			ss := strsplit(v,",")
			if (ss.length() = 1)
				this.spawns[index].push({count:0,id:0,delay:ss[1]})
			else
				this.spawns[index].push({count:ss[1],id:ss[2],delay:ss[3]})
		}
		this.waveMax++
	}
	
	SetData() {
		this.spawnDelay := this.spawns[this.waveIndex][this.spawnIndex].delay
		this.spawnID := this.spawns[this.waveIndex][this.spawnIndex].id
		this.spawnCount := this.spawns[this.waveIndex][this.spawnIndex].count
	}
	
	StartWave(index) {
		if (index = 0)
			index := this.waveIndex
		this.game.data.enemies := []
		this.waveIndex := index
		this.delay := 0
		this.count := 0
		this.spawnIndex := 1
		this.spawning := 1
		this.spawnIndexCount := this.spawns[index].length()
		this.SetData()
		this.game.data.running := 1
	}
	
	Update() {
		if (!this.game.data.running)
			return
	
		if (this.spawning) {
			if (this.delay <= 0) {
				if (this.spawnCount > 0)
					this.game.data.enemies.push(new enemyclass(this.game,this.spawns[this.waveIndex][this.spawnIndex].id))
				this.count++
				this.delay := this.spawnDelay
				if (this.count >= this.spawnCount) {
					if (this.spawnIndex = this.spawnIndexCount) {
						this.spawning := 0
						return
					}
					this.count := 0
					this.spawnIndex++
					this.SetData()
				}
			} else {
				this.delay -= this.game.timeScale
			}
		} else if (this.game.data.running) {
			if (this.game.data.enemies.length() = 0) {
				this.waveIndex++
				this.game.data.running := 0
			}
		}
	}
}

class placeMarkerClass {
	__New(game) {
		this.active := 0
		this.img := ""
		this.range := 0
		this.x := 0
		this.y := 0
		this.game := game
		this.id := 0
		this.cost := 99999
	}
	
	SetMarker(ID,img,range,cost) {
		this.id := id
		this.img := img
		this.range := range
		this.active := 1
		this.cost := cost
	}
	
	ClearMarker() {
		this.active := 0
	}
	
	Update() {
		if (!this.active)
			return
		if (this.game.rbutton) {
			this.active := 0
			return
		}
		if (this.game.lbutton) {
			this.game.lbutton := 0
			if (this.game.data.money >= this.cost) {
				this.game.data.money -= this.cost
				if (this.id = 0)
					this.game.data.towers.push(new tower1Class(this.game,this.x,this.y,1))
				else if (this.id = 1)
					this.game.data.towers.push(new tower2Class(this.game,this.x,this.y,1))
				else if (this.id = 2)
					this.game.data.towers.push(new tower3Class(this.game,this.x,this.y,1))
			}
			this.active := 0
		} else {
			this.x := this.game.mouseX
			this.y := this.game.mouseY
			this.Draw()
		}
	}
	
	Draw() {
		this.game.FillEllipse(this.x,this.y,this.range,this.range,0x33FFFFFF)
		this.game.DrawEllipse(this.x,this.y,this.range,this.range,0xFFFFFFFF)
		this.game.DrawImage(this.img,this.x,this.y,0,0,0,0,0,0,1,1)
	}
}

class pathGuideClass {
	__New(game) {
		this.node := 2
		this.x := game.data.path[1].x
		this.y := game.data.path[1].y
		this.angle := arctan2(this.y - game.data.path[2].y, this.x - game.data.path[2].x) * 57.295779
		this.speed := 1000
		this.game := game
		this.alpha := 1
		this.blink := -0.005
	}
	
	GetPathPosition() {
		speed := this.speed * this.game.timeScale
		steps := ceil(speed * 0.3) + ceil(this.game.gameSpeed)
		speed /= steps
		loop % steps {
			dx := this.game.data.path[this.node].x-this.x
			dy := this.game.data.path[this.node].y-this.y
			dist := sqrt(dx*dx+dy*dy)
			dx/=dist
			dy/=dist
			if (dist < 2) {
				this.node++
				
				if (this.node > this.game.data.path.length()) {
					this.node := 2
					this.x := this.game.data.path[1].x
					this.y := this.game.data.path[1].y
					
				}
				if ((this.node+1) <= this.game.data.path.length())
					this.angle := Arctan2(this.y - this.game.data.path[this.node+1].y, this.x - this.game.data.path[this.node+1].x) * 57.295779
				
			}
			this.x += (dx * speed)
			this.y += (dy * speed)
		}
	}
	
	Update() {
		if (this.game.data.running)
			return
		
		this.alpha += this.blink
		if (this.alpha < 0 or this.alpha > 1) {
			this.blink *= -1
			this.alpha+=this.blink
		}
			
		this.GetPathPosition()
		
		this.draw()
	}
	
	Draw() {
		this.game.drawimage("resources\images\arrowg.png",this.x,this.y,0,0,0,0,0,0,1,1,this.angle-180)
		
		alp := round(this.alpha*255)
		
		this.game.drawtext("~ Press SPACEBAR to start wave ~",0,50,38,(alp<<24) + 0xFFFFFF,"Arial","acenter w800")
		
	}
}

class tower1Class {

	__New(game,x,y,active:=0) {
		this.x := x
		this.y := y
		this.active := active
		this.name := "Laser"
		this.cost := 100
		this.attacksPerSecond := 1 / 3
		this.attackReset := 0
		this.damage := 15
		this.range := 110
		this.desc := "Weak but good range and fire rate"
		this.img := "resources\images\tower_top.png"
		this.imgBase := "resources\images\tower_base.png"
		this.imgTop := "resources\images\tower_top.png"
		this.game := game
		this.angle := 0
		this.angleRad := 0
		this.barrelX := -25
		this.barrelY := 25
	}
	
	GetBarrelPosition(byref x, byref y) {
		rad := this.angleRad + 1.5708
		x := this.x + this.barrelX * sin(rad)
		y := this.y + this.barrelY * cos(rad)
	}
	
	Update() {
		if (this.active) {
			ci := 0
			larg := 0
			for k,v in this.game.data.enemies
			{
				if (v.active and v.health > 0 and v.trav > larg and this.EnemyInRange(v,dist)) {
					larg := v.trav
					ci := a_index
				}
			}
			if (ci) {
				this.angleRad := arctan2(this.y - this.game.data.enemies[ci].y, this.x - this.game.data.enemies[ci].x)
				this.angle := this.angleRad * 57.295779
			}
			if (this.attackReset <= 0) {
				if (ci) {
					v := this.game.data.enemies[ci]
					this.GetBarrelPosition(bx,by)
					part := new particleClass(this.game,bx,by)
					part.SetImage("resources\images\beam4.png")
					part.scaleX := GetDist(bx,by,v.x,v.y)
					part.x -= ((bx-v.x)/2)
					part.y -= ((by-v.y)/2)
					part.rotation := this.angle
					part.alphaInc := -12.0
					this.game.data.particles.push(part)
					
					hit := new particleClass(this.game,v.x,v.y)
					hit.SetImage("resources\images\laserhit.png")
					hit.rotation := random(0,359)
					hit.lifespan := 0.1
					this.game.data.particles.push(hit)
					
					this.lx1 := v.x
					this.ly1 := v.y
					this.lx2 := bx
					this.ly2 := by
					this.attackReset := this.attacksPerSecond
					v.health -= this.damage
				}
			} else {
				this.attackReset -= this.game.timeScale
			}
			
			
			
			this.drawActive()
		} else {
			if (this.game.MouseInRegion(this.x,this.y,this.x+64,this.y+64)) {
				this.game.data.hoverText := 1
				this.game.drawtext(this.name,800,5,26,0xFFFFA200,"Arial","acenter w200")
				this.game.drawtext("Cost: " this.cost "`nDamage: " this.damage "`nRange: " this.range,810,50,18,0xFF009EFF,"Arial")
				this.game.drawtext(this.desc,800,140,20,0xFFEFF521,"Arial","acenter w200")
				if (this.game.lbutton and this.game.data.money >= this.cost) {
					this.game.data.placeMarker.SetMarker(0,this.img,this.range,this.cost)
				}
			}
			
			this.DrawInactive()
		}
	}
	
	DrawInactive() {
		w := h := 64
		if (this.cost <= this.game.data.money)
			this.game.drawimage("resources\images\buy.png",this.x+32,this.y+32,70,70,0,0,64,64,1,1)
		this.game.drawimage(this.imgBase,this.x,this.y,w,h)
		this.game.drawimage(this.imgTop,this.x,this.y,w,h)
		if (this.game.MouseInRegion(this.x,this.y,this.x+w,this.y+h)) {
			this.game.DrawRectangle(this.x,this.y,w,h,0xFFFFFFFF,3)
		}
	}
	
	DrawActive() {
		w := h := 48
		this.game.drawimage(this.imgBase,this.x,this.y,w,h,0,0,0,0,1,1)
		this.game.drawimage(this.imgTop,this.x,this.y,w,h,0,0,0,0,1,1,this.angle)
		
		
		if (this.game.MouseInRegion(this.x-24,this.y-24,this.x-24+w,this.y-24+h)) {
			this.game.FillEllipse(this.x,this.y,this.range,this.range,0x33FFFFFF)
			this.game.DrawEllipse(this.x,this.y,this.range,this.range,0xFFFFFFFF)
		}
	}
	
	EnemyInRange(enemy,byref dist) {
		dx := this.x - enemy.x
		dy := this.y - enemy.y
		dist := sqrt(dx*dx + dy*dy)
		return (dist < (this.range + enemy.colSize))
	}
}















class tower2Class {

	__New(game,x,y,active:=0) {
		this.x := x
		this.y := y
		this.active := active
		this.name := "Cannon"
		this.cost := 220
		this.attacksPerSecond := 1 / 0.8
		this.attackReset := 0
		this.damage := 100
		this.range := 230
		this.desc := "Slow but powerful"
		this.img := "resources\images\tower_base2.png"
		this.imgBase := "resources\images\tower_base2.png"
		this.imgTop := "resources\images\tower_top2.png"
		this.projImg := "resources\images\proj1.png"
		this.projSpeed := 1700
		this.game := game
		this.angle := 0
		this.angleRad := 0
		this.barrelX := -24
		this.barrelY := 24
	}
	
	GetBarrelPosition(byref x, byref y) {
		rad := this.angleRad + 1.5708
		x := this.x + this.barrelX * sin(rad)
		y := this.y + this.barrelY * cos(rad)
	}
	
	Update() {
		if (this.active) {
			ci := 0
			larg := 0
			for k,v in this.game.data.enemies
			{
				if (v.active and v.health > 0 and v.trav > larg and this.EnemyInRange(v,dist)) {
					larg := v.trav
					ci := a_index
				}
			}
			if (ci) {
				this.angleRad := arctan2(this.y - this.game.data.enemies[ci].y, this.x - this.game.data.enemies[ci].x)
				this.angle := this.angleRad * 57.295779
			}
			if (this.attackReset <= 0) {
				if (ci) {
					v := this.game.data.enemies[ci]
					this.GetBarrelPosition(bx,by)
					this.attackReset := this.attacksPerSecond
					proj := new projectileClass(this.game,bx,by,this.projImg)
					proj.speed := this.projSpeed
					proj.damage := this.damage
					proj.SetTargetAngle(this.angleRad)
					this.game.data.projectiles.push(proj)
					loop 3 {
						smoke := new particleClass(this.game,bx+random(-5,5),by+random(-5,5))
						smoke.SetImage("resources\images\smoke.png")
						smoke.rotationInc := random(-100,100)
						smoke.alphaInc := random(-1,-0.5)
						smoke.scaleInc := random(-0.4,-0.1)
						smoke.scale := random(1.0,1.6)
						this.game.data.particles.push(smoke)
					}
				}
			} else {
				this.attackReset -= this.game.timeScale
			}
			
			
			
			this.drawActive()
		} else {
			if (this.game.MouseInRegion(this.x,this.y,this.x+64,this.y+64)) {
				this.game.data.hoverText := 1
				this.game.drawtext(this.name,800,5,26,0xFFFFA200,"Arial","acenter w200")
				this.game.drawtext("Cost: " this.cost "`nDamage: " this.damage "`nRange: " this.range,810,50,18,0xFF009EFF,"Arial")
				this.game.drawtext(this.desc,800,140,20,0xFFEFF521,"Arial","acenter w200")
				if (this.game.lbutton and this.game.data.money >= this.cost) {
					this.game.data.placeMarker.SetMarker(1,this.img,this.range,this.cost)
				}
			}
			this.DrawInactive()
		}
	}
	
	DrawInactive() {
		w := h := 64
		if (this.cost <= this.game.data.money)
			this.game.drawimage("resources\images\buy.png",this.x+32,this.y+32,70,70,0,0,64,64,1,1)
		this.game.drawimage(this.imgBase,this.x,this.y,w,h)
		this.game.drawimage(this.imgTop,this.x,this.y,w,h)
		if (this.game.MouseInRegion(this.x,this.y,this.x+w,this.y+h)) {
			this.game.DrawRectangle(this.x,this.y,w,h,0xFFFFFFFF,3)
		}
	}
	
	DrawActive() {
		w := h := 48
		this.game.drawimage(this.imgBase,this.x,this.y,w,h,0,0,0,0,1,1)
		this.game.drawimage(this.imgTop,this.x,this.y,w,h,0,0,0,0,1,1,this.angle)
		
		if (this.game.MouseInRegion(this.x-24,this.y-24,this.x-24+w,this.y-24+h)) {
			this.game.FillEllipse(this.x,this.y,this.range,this.range,0x33FFFFFF)
			this.game.DrawEllipse(this.x,this.y,this.range,this.range,0xFFFFFFFF)
		}
	}
	
	EnemyInRange(enemy,byref dist) {
		dx := this.x - enemy.x
		dy := this.y - enemy.y
		dist := sqrt(dx*dx + dy*dy)
		return (dist < (this.range + enemy.colSize))
	}
}





class tower3Class {

	__New(game,x,y,active:=0) {
		this.x := x
		this.y := y
		this.active := active
		this.name := "Ferret"
		this.cost := 350
		this.attacksPerSecond := 1 / 1.5
		this.attackReset := 0
		this.damage := 33
		this.range := 100
		this.desc := "Good area"
		this.img := "resources\images\tower_top3.png"
		this.imgTop := "resources\images\tower_top3.png"
		this.projImg := "resources\images\proj2.png"
		this.projSpeed := 1700
		this.game := game
		this.angle := 0
		this.angleRad := 0
		this.barrelX := -24
		this.barrelY := 24
	}
	
	GetBarrelPosition(byref x, byref y) {
		rad := this.angleRad + 1.5708
		x := this.x + this.barrelX * sin(rad)
		y := this.y + this.barrelY * cos(rad)
	}
	
	Update() {
		if (this.active) {
			ci := 0
			larg := 0
			for k,v in this.game.data.enemies
			{
				if (v.active and v.health > 0 and v.trav > larg and this.EnemyInRange(v,dist)) {
					larg := v.trav
					ci := a_index
				}
			}
			if (this.attackReset <= 0) {
				if (ci) {
					v := this.game.data.enemies[ci]
					this.GetBarrelPosition(bx,by)
					this.attackReset := this.attacksPerSecond
					rads := 0
					loop 8 {
						bx := this.x + (20 * cos(rads))
						by := this.y + (20 * sin(rads))
						
						proj := new projectileClass(this.game,bx,by,this.projImg)
						proj.speed := this.projSpeed
						proj.damage := this.damage
						proj.lifeSpan := 0.07
						proj.SetTargetAngle(rads,1)
						this.game.data.projectiles.push(proj)
						
						smoke := new particleClass(this.game,bx,by)
						smoke.SetImage("resources\images\smoke2.png")
						smoke.alphaInc := -15
						smoke.scaleX := 1.2
						smoke.scaleY := 1.2
						smoke.rotation := (rads*57.295779)-180

						this.game.data.particles.push(smoke)
						
						rads += 0.785385
					}
				}
			} else {
				this.attackReset -= this.game.timeScale
			}
			
			
			
			this.drawActive()
		} else {
			if (this.game.MouseInRegion(this.x,this.y,this.x+64,this.y+64)) {
				this.game.data.hoverText := 1
				this.game.drawtext(this.name,800,5,26,0xFFFFA200,"Arial","acenter w200")
				this.game.drawtext("Cost: " this.cost "`nDamage: " this.damage "`nRange: " this.range,810,50,18,0xFF009EFF,"Arial")
				this.game.drawtext(this.desc,800,140,20,0xFFEFF521,"Arial","acenter w200")
				if (this.game.lbutton and this.game.data.money >= this.cost) {
					this.game.data.placeMarker.SetMarker(2,this.img,this.range,this.cost)
				}
			}
			this.DrawInactive()
		}
	}
	
	DrawInactive() {
		w := h := 64
		if (this.cost <= this.game.data.money)
			this.game.drawimage("resources\images\buy.png",this.x+32,this.y+32,70,70,0,0,64,64,1,1)
		this.game.drawimage(this.imgTop,this.x,this.y,w,h)
		if (this.game.MouseInRegion(this.x,this.y,this.x+w,this.y+h)) {
			this.game.DrawRectangle(this.x,this.y,w,h,0xFFFFFFFF,3)
		}
	}
	
	DrawActive() {
		w := h := 48
		this.game.drawimage(this.imgTop,this.x,this.y,w,h,0,0,0,0,1,1,this.angle)
		
		if (this.game.MouseInRegion(this.x-24,this.y-24,this.x-24+w,this.y-24+h)) {
			this.game.FillEllipse(this.x,this.y,this.range,this.range,0x33FFFFFF)
			this.game.DrawEllipse(this.x,this.y,this.range,this.range,0xFFFFFFFF)
		}
	}
	
	EnemyInRange(enemy,byref dist) {
		dx := this.x - enemy.x
		dy := this.y - enemy.y
		dist := sqrt(dx*dx + dy*dy)
		return (dist < (this.range + enemy.colSize))
	}
}




GetDist(x1,y1,x2,y2) {
	dx := x1 - x2
	dy := y1 - y2
	return sqrt(dx*dx + dy*dy)
}






class enemyClass {

	__New(game,id:=0) {
		this.node := 1
		this.x := game.data.path[1].x
		this.y := game.data.path[1].y
		this.node := 2
		this.speed := (id = 0 ? 150 : 300)
		this.size := 32
		this.colSize := this.size/2
		this.img := (id = 0 ? "resources\images\mon3.png" : "resources\images\monAttack.png")
		this.rotation := random(0,359)
		this.rotSpeed := random(50,200)
		this.game := game
		this.active := 1
		this.health := (id = 0 ? 100 : 50)
		this.maxHealth := this.health
		this.damage := (id = 0 ? 1 : 1)
		this.reward := (id = 0 ? 10 : 15)
		this.trav := 0
	}
	
	GetPathPosition() {
		speed := this.speed * this.game.timeScale
		steps := ceil(speed * 0.3) + ceil(this.game.gameSpeed)
		speed /= steps
		loop % steps {
			dx := this.game.data.path[this.node].x-this.x
			dy := this.game.data.path[this.node].y-this.y
			dist := sqrt(dx*dx+dy*dy)
			dx/=dist
			dy/=dist
			if (dist < 2) {
				this.node++
				
				if (this.node > this.game.data.path.length()) {
					this.active := 0
					return 0 
				}
				if ((this.node+1) <= this.game.data.path.length())
					this.angle := Arctan2(this.y - this.game.data.path[this.node+1].y, this.x - this.game.data.path[this.node+1].x) * 57.295779
				
			}
			this.x += (dx * speed)
			this.y += (dy * speed)
			this.trav += abs((dx+dy))*speed
		}
		return 1
	}
	
	Update() {
		if (!this.active)
			return
		if (!this.GetPathPosition()) {
			this.game.data.lives--
			return
		}
		if (this.health <= 0) {
			this.active := 0
			part := new particleClass(this.game,this.x,this.y)
			part.SetImage(this.img)
			part.rotation := this.rotation
			part.rotationInc := random(-1000,1000)
			part.scaleInc := -0.2
			part.alphaInc := -1
			this.game.data.particles.push(part)
			this.game.data.money += this.reward
			return
		}
		this.rotation += (this.rotSpeed * this.game.timeScale)
		if (this.rotation > 359)
			this.rotation -= 360
		this.draw()
	}
	
	DrawHealthBar() {
		if (!this.active)
			return
		w := (this.health / this.maxHealth) * 32
		if (w < 3)
			w := 3
		this.game.FillRectangle(this.x-16,this.y-21,32,4,0xFF000000)
		this.game.FillRectangle(this.x-15,this.y-20,30,2,0xFFFF0000)
		this.game.FillRectangle(this.x-15,this.y-20,w-2,2,0xFF00FF00)
	}
	
	Draw() {
		this.game.DrawImage(this.img,this.x,this.y,this.size,this.size,0,0,0,0,1,1,this.rotation)
	}
	
}


Random(min,max) {
	random,res,min,max
	return res
}



Arctan2(y,x) {
	if (x > 0)
		return Atan(y/x)
	if (x < 0) {
		if (y >= 0)
			return Atan(y/x) + 3.141592
		if (y < 0)
			return Atan(y/x) - 3.141592
	}
	if (y > 0)
		return 3.141592/2
	if (y < 0)
		return -3.141592/2
	return 0
}


;not the best way to do this but it's easy
setupPath:
game.data.path := []
game.data.path.push({x:78,y:-20})
game.data.path.push({x:74,y:72})
game.data.path.push({x:74,y:135})
game.data.path.push({x:77,y:193})
game.data.path.push({x:80,y:220})
game.data.path.push({x:85,y:252})
game.data.path.push({x:90,y:291})
game.data.path.push({x:94,y:340})
game.data.path.push({x:94,y:371})
game.data.path.push({x:93,y:385})
game.data.path.push({x:82,y:455})
game.data.path.push({x:77,y:490})
game.data.path.push({x:71,y:527})
game.data.path.push({x:71,y:556})
game.data.path.push({x:71,y:577})
game.data.path.push({x:75,y:600})
game.data.path.push({x:79,y:629})
game.data.path.push({x:88,y:654})
game.data.path.push({x:98,y:679})
game.data.path.push({x:111,y:695})
game.data.path.push({x:129,y:705})
game.data.path.push({x:153,y:713})
game.data.path.push({x:179,y:718})
game.data.path.push({x:204,y:721})
game.data.path.push({x:232,y:721})
game.data.path.push({x:257,y:714})
game.data.path.push({x:277,y:702})
game.data.path.push({x:286,y:680})
game.data.path.push({x:286,y:659})
game.data.path.push({x:277,y:641})
game.data.path.push({x:261,y:626})
game.data.path.push({x:237,y:612})
game.data.path.push({x:218,y:602})
game.data.path.push({x:197,y:587})
game.data.path.push({x:184,y:573})
game.data.path.push({x:178,y:544})
game.data.path.push({x:176,y:514})
game.data.path.push({x:181,y:487})
game.data.path.push({x:189,y:463})
game.data.path.push({x:206,y:441})
game.data.path.push({x:228,y:422})
game.data.path.push({x:271,y:403})
game.data.path.push({x:303,y:387})
game.data.path.push({x:345,y:369})
game.data.path.push({x:501,y:289})
game.data.path.push({x:552,y:264})
game.data.path.push({x:584,y:248})
game.data.path.push({x:610,y:221})
game.data.path.push({x:620,y:197})
game.data.path.push({x:619,y:165})
game.data.path.push({x:614,y:139})
game.data.path.push({x:604,y:122})
game.data.path.push({x:581,y:101})
game.data.path.push({x:556,y:86})
game.data.path.push({x:531,y:78})
game.data.path.push({x:503,y:74})
game.data.path.push({x:477,y:73})
game.data.path.push({x:459,y:73})
game.data.path.push({x:444,y:82})
game.data.path.push({x:433,y:97})
game.data.path.push({x:426,y:117})
game.data.path.push({x:423,y:141})
game.data.path.push({x:424,y:163})
game.data.path.push({x:431,y:186})
game.data.path.push({x:443,y:219})
game.data.path.push({x:463,y:246})
game.data.path.push({x:497,y:283})
game.data.path.push({x:520,y:311})
game.data.path.push({x:542,y:346})
game.data.path.push({x:568,y:381})
game.data.path.push({x:584,y:404})
game.data.path.push({x:597,y:429})
game.data.path.push({x:610,y:454})
game.data.path.push({x:618,y:485})
game.data.path.push({x:621,y:514})
game.data.path.push({x:618,y:543})
game.data.path.push({x:613,y:573})
game.data.path.push({x:602,y:604})
game.data.path.push({x:587,y:631})
game.data.path.push({x:573,y:666})
game.data.path.push({x:548,y:721})
game.data.path.push({x:527,y:754})
game.data.path.push({x:501,y:797})
game.data.path.push({x:490,y:810})
return
