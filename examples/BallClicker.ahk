#include ShinsGameClass.ahk
setbatchlines,-1 ;VERY important for stable fps

boxSize := 128 ;walls will be 128x128 pixels
boxWidth := 10 ;10 wall columns
boxHeight := 7 ;7 wall rows
playArea := {x:boxSize,y:boxSize,w:boxSize*(boxWidth-2),h:boxSize*(boxHeight-2)}

score := 0
walls := []
floaters := []

game := new ShinsGameClass(0,0,boxWidth*boxSize,boxHeight*boxSize,"Bouncy Ball Clicker")

;create the left and right walls
loop % boxWidth {
	x := (a_index-1) * boxSize
	walls.push(new wallClass("resources\images\box.png",x,0,boxSize))
	walls.push(new wallClass("resources\images\box.png",x,game.height-boxSize,boxSize))
}
;create the top and bottom walls
loop % boxHeight-2 {
	y := a_index * boxSize
	walls.push(new wallClass("resources\images\box.png",0,y,boxSize))
	walls.push(new wallClass("resources\images\box.png",game.width-boxSize,y,boxSize))
}

;create and instance of the ball class
ball := new ballClass(playArea.x+(playArea.w/2),playArea.y+(playArea.h/2),64)

restartButton := new buttonClass(10,60,120,30,"Restart")
ezModeButton := new buttonClass(160,60,120,30,"EZ Mode",0xFF60405E)
ezMode2Button := new buttonClass(305,60,200,30,"SUPER EZ Mode",0xFFF354E7)




;vsync is enabled so a loop without a sleep will provde the best results
loop {
	if (game.BeginDraw()) {
			
		game.DrawImage("resources\images\woodBack.png",0,0,game.width,game.height)

		
		for k,v in walls
			v.update(game)
		
		if (restartButton.Update(game) and game.lbutton) {
			ball := "" ;destroys ball class
			ball := new ballClass(playArea.x+(playArea.w/2),playArea.y+(playArea.h/2),64)
			score := 0
			game.lbutton := 0
		}
		if (ezModeButton.Update(game) and game.lbutton) {
			ball := "" ;destroys ball class
			ball := new ballClass(playArea.x+(playArea.w/2),playArea.y+(playArea.h/2),128)
			score := 0
			game.lbutton := 0
		}
		if (ezMode2Button.Update(game) and game.lbutton) {
			ball := "" ;destroys ball class
			ball := new ballClass(playArea.x+(playArea.w/2),playArea.y+(playArea.h/2),256)
			score := 0
			game.lbutton := 0
		}
		
		if (ball.Update(game,walls)) { ;if the ball is currently hovered over
			if (game.lbutton) { ;if clicked and hovered then you got it
				score += 10
				ball.Respawn(boxSize+ball.radius+5,boxSize+ball.radius+5,game.width-boxSize-ball.radius+5,game.height-boxSize-ball.radius+5)
				ball.speed+=0.1
				ball.radius *= 0.995
				floaters.push(new floatTextClass(game.mouseX,game.mouseY-30,"Nice!",0xFF00))
			}
		} else if (game.lbutton) { ;if the ball was not hovered over and a click happened
			ball.SetRandomDir()
			floaters.push(new floatTextClass(game.mouseX,game.mouseY-30,(random(1,500) = 1 ? "You really suck at this!" : "Whoops!"),0xFF0000))
		} else if (game.rbutton) { ;cheater button lol
			score += 10
			ball.Respawn(playArea.x+ball.radius+5,playArea.y+ball.radius+,playArea.x+playArea.w-ball.radius-5,playArea.y+playArea.h-ball.radius-5)
			ball.speed+=0.1
			ball.radius *= 0.995
			floaters.push(new floatTextClass(game.mouseX,game.mouseY-30,"Cheats!",0xFFFF))
		}
		
		
		
		;loop through the floating text and draw/remove as needed
		i := 1
		while(i <= floaters.length()) {
			if (!floaters[i].update(game)) {
				floaters.removeat(i)
			} else {
				i++
			}
		}
		
		game.DrawText("Hello World!",playArea.x+playArea.w+300,100,64,0xFF000000)
	
		game.FillRectangle(10,10,400,30,0x77000000)
		game.DrawRectangle(10,10,400,30,0xFF000000)
		game.drawtext("Score: " score,20,13,20,0xFFFFFFFF)
		game.drawtext("FPS: " game.fps,0,13,20,0xFFFFFFFF,,"w400 aright")
		
		game.EndDraw()
	}
}

return



class wallClass {
	__New(image,x,y,size) {
		this.image := image
		this.x := x
		this.y := y
		this.x2 := x+size
		this.y2 := y+size
		this.size := size
		
	}
	
	Update(game) {
		game.DrawImage(this.image,this.x,this.y,this.size,this.size)
	}
}

class ballClass {
	__New(x,y,radius) {
		this.x := x
		this.y := y
		this.speed := 1
		this.radius := radius
		this.SetRandomDir()
	}
	
	Respawn(x1,y1,x2,y2) {
		this.x := random(x1,x2)
		this.y := random(y1,y2)
		this.SetRandomDir()
	}
	
	SetRandomDir() {
		this.xdir := random(0.20,0.80)
		this.ydir := 1 - this.xdir
		this.xdir *= (random(0,1) ? 1 : -1)
		this.ydir *= (random(0,1) ? 1 : -1)
	}
	
	Update(game,walls) {
		
		xmovement := this.xdir * this.speed
		ymovement := this.ydir * this.speed
		
		this.x += xmovement
		this.y += ymovement
		
		x1 := this.x-this.radius
		y1 := this.y-this.radius
		x2 := x1 + this.radius*2
		y2 := y1 + this.radius*2
		
		if ((this.xdir < 0 and this.CanMove(this.x-this.radius+xmovement,this.y,walls)) or (this.xdir > 0 and this.CanMove(this.x+(this.radius)+xmovement,this.y,walls))) ;left
			this.x += xmovement
		else
			this.xdir *= -1
		if ((this.ydir < 0 and this.CanMove(this.x,this.y-this.radius+ymovement,walls)) or (this.ydir > 0 and this.CanMove(this.x,this.y+(this.radius)+ymovement,walls))) ;left
			this.y += ymovement
		else
			this.ydir *= -1
	
		if (game.GetDistance(game.mouseX,game.mouseY,this.x,this.y) <= (this.radius*1.2)) {
			game.FillCircle(this.x,this.y,this.radius,0xFF14C334)
			game.FillEllipse(this.x,this.y+this.radius*0.45,this.radius*0.80,this.radius*0.5,0x22FFFFFF)
			game.FillEllipse(this.x,this.y+this.radius*0.11,this.radius*0.9,this.radius*0.9,0x33FFFFFF)
			game.FillEllipse(this.x,this.y+this.radius*-0.55,this.radius*0.60,this.radius*0.4,0x55FFFFFF)
			game.FillCircle(this.x,this.y,this.radius,0x44FFFFFF)   
			game.DrawCircle(this.x,this.y,this.radius,0xFF000000,2)
			return 1
		} else {
			game.FillCircle(this.x,this.y,this.radius,0xFFE80505)
			game.FillEllipse(this.x,this.y+this.radius*0.45,this.radius*0.80,this.radius*0.5,0x22FFFFFF)
			game.FillEllipse(this.x,this.y+this.radius*0.11,this.radius*0.9,this.radius*0.9,0x33FFFFFF)
			game.FillEllipse(this.x,this.y+this.radius*-0.55,this.radius*0.60,this.radius*0.4,0x55FFFFFF)
			game.DrawCircle(this.x,this.y,this.radius,0xFF000000,1)
		}
		
		
		
		return 0
		
	}
	CanMove(x,y,walls) {
		for k,v in walls
		{
			if (x >= v.x and y >= v.y and x <= v.x2 and y <= v.y2)
				return 0
		}
		return 1
	}
	
}

class floatTextClass {
	__New(x,y,text,color) {
		this.x := x
		this.y := y
		this.xdir := random(-2.0,2.0)
		this.ydir := random(-2.0,-1.0)
		this.text := text
		this.color := color
		this.alpha := 255
	}
	
	Update(game) {
		if (this.alpha > 90)
			game.DrawText(this.text,this.x-200,this.y-24,48,(this.alpha<<24)+this.color,"Arial","ds77000000 acenter w400")
		else
			game.DrawText(this.text,this.x-200,this.y-24,48,(this.alpha<<24)+this.color,"Arial","acenter w400")
		this.alpha -= 2
		this.x+=this.xdir
		this.y+=this.ydir
		if (this.y < -30 or this.alpha <= 0)
			return 0
		return 1
	}
}


class buttonClass {
	__New(x,y,w,h,text,color:=0xFF333333) {
		this.x := x
		this.y := y
		this.w := w
		this.h := h
		this.fontSize := floor(h*0.8)
		this.text := text
		this.color := color
	}
	Update(game) {
	
		game.FillRectangle(this.x,this.y,this.w,this.h,this.color)
		game.DrawRectangle(this.x,this.y,this.w,this.h,0xFF000000)
		
		if (game.MouseInRegion(this.x,this.y,this.x+this.w,this.y+this.h)) {
			game.FillRectangle(this.x,this.y,this.w-1,this.h-1,0x66FFFFFF)
			game.DrawText(this.text,this.x,this.y,this.fontSize,0xFFFFFFFF,"Arial","w" this.w " acenter")
			return 1
		} else {
			game.DrawText(this.text,this.x,this.y,this.fontSize,0xFFFFFFFF,"Arial","w" this.w " acenter")
		}
		return 0
	}
}

Random(min,max) {
	random,result,min,max
	return result
}

f9::Reload
f8::exitapp
