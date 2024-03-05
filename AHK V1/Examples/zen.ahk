#include ../ShinsGameClass.ahk
#singleinstance, force
setbatchlines,-1


game := new ShinsGameClass(0,0,640,640,"Zen by Spawnova - ESC to close",1,"ZenDemo")

game.data.colors := {0:0xFF000000,1:0xFFCCCCCC}
game.data.tiles := []
loop 20 {
	x := a_index-1
	loop 20 {
		y := a_index-1
		game.data.tiles[x,y] := {x1:x*32,y1:y*32,x2:(x*32)+32,y2:(y*32)+32,c:(x < 10 ? 0 : 1)}
	}
}

balls := [new _Ball(game,random(32,290),random(32,610),1),new _Ball(game,random(360,610),random(32,610),0)]


loop {
	if (game.begindraw()) {
		
		for k,v in balls
			v.update()

		loop 20 {
			x := a_index-1
			loop 20 {
				y := a_index-1
				colID := game.data.tiles[x,y].c
				game.fillrectangle(x*32,y*32,32,32,game.data.colors[colID])

				;draw borders based on tile color
				if (x = 0)
					game.drawline(1,y*32,1,(y*32)+32,game.data.colors[!colID],6)
				else if (x = 19)
					game.drawline(639,y*32,639,(y*32)+32,game.data.colors[!colID],6)
				if (y = 0)
					game.drawline(x*32,1,(x*32)+32,1,game.data.colors[!colID],6)
				else if (y = 19)
					game.drawline(x*32,639,(x*32)+32,639,game.data.colors[!colID],6)

			}
		}

		for k,v in balls
			v.draw()

		game.endDraw()
	}
}

exitapp


f9::reload
esc::exitapp




class _Ball {
	__New(game,x,y,color) {
		this.game := game
		this.x := x
		this.y := y
		this.colorID := color
		this.color := game.data.colors[color]

		angle := random(30,70) * 0.0174533

		this.xSpeed := 8 * cos(angle)
		this.ySpeed := 8 * sin(angle)
	}	

	Update() {
		xx := this.x + this.xSpeed
		yy := this.y + this.ySpeed
		if (yy > 640-32 or yy < 0) {
			this.ySpeed *= -1
			yy += this.ySpeed
		}
		if (xx > 640-32 or xx < 0) {
			this.xSpeed *= -1
			xx += this.xSpeed
		}
		hitx := hity := 0
		loop 20 {
			x := a_index-1
			loop 20 {
				y := a_index-1
				tile := this.game.data.tiles[x,y]
				if (tile.c != this.colorID)
					continue

				if (tile.x1 < xx+32 and tile.x2 > xx and tile.y1 < yy+32 and tile.y2 > yy) {
					this.game.data.tiles[x,y].c := (!this.colorID)
					overlapX := min(abs(xx - tile.x1 - 16), 16)
					overlapY := min(abs(yy - tile.y1 - 16), 16)
				
					if (overlapX <= overlapY) {
						;msgbox % overlapX "`n" overlapY
						this.ySpeed *= -1
						yy += this.ySpeed
					} else {
						this.xSpeed *= -1
						xx += this.xSpeed
					}
				}
			}
		}
		this.x := xx
		this.y := yy
	}

	Draw() {
		this.game.fillCircle(this.x+16,this.y+16,16,this.color)
	}
}
