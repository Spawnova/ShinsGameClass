;Direct2d game class by Spawnova (9/19/2022)
;https://github.com/Spawnova/ShinsGameClass
;
;I'm not a professional programmer, I do this for fun, if it doesn't work for you I can try and help
;but I can't promise I will be able to solve the issue
;
;Special thanks to teadrinker for helping me understand some 64bit param structures! -> https://www.autohotkey.com/boards/viewtopic.php?f=76&t=105420

#Requires AutoHotkey v2+

class ShinsGameClass {

	;x							:		x pos of game window, if 0 then centered
	;y							:		y pos of game window, if 0 then centered
	;width						:		width of game window
	;height						:		height of game window
	;titleName					:		title name of the game window
	;vsync						:		vsync on or off
	;guiID						:		name of the ahk gui id for the game window
	
	__New(x,y,width,height,titleName:="Game Title",vsync:=1) {

		;[input variables] you can change these to affect the way the script behaves
		
		this.interpolationMode := 1 ;0 = nearestNeighbor, 1 = linear ;affects DrawImage() scaling 
		this.data := Map() 			;reserved name for general data storage
		this.minWidth := 1
		this.minHeight := 1
	
		;[output variables] you can read these to get extra info, DO NOT MODIFY THESE
		
		this.x := x := (x=0?(a_screenwidth/2)-(width/2):x)		;window x position
		this.y := y := (y=0?(a_screenheight/2)-(height/2):y)		;window y position
		this.width := width										;window width
		this.height := height									;window height
		
	
		;#############################
		;	Setup internal stuff
		;#############################
		this.bits := (a_ptrsize == 8)
		this.imageCache := Map()
		this.fonts := Map()
		this.lastCol := 0
		this.iconic := 0
		this.maximized := 0
		this.clicks := 0
		this.mouseX := -1
		this.mouseY := -1
		this.mouseInClient := 0
		this.fps := 0
		this.frames := 0
		this.frameSum := 0
		this.deltaTime := 0
		this.deltaLast := 0
		this.deltaTotal := 0
		this.gameSpeed := 1
		this.timeScale := 0
		this.title := titleName
		this.newWidth := width
		this.newHeight := height
		this.drawing := 0
		this.sizeChangeReady := 0		
		pOut := 0
		
		this._cacheImage := this.mcode("VVdWMfZTg+wMi0QkLA+vRCQoi1QkMMHgAoXAfmSLTCQki1wkIA+26gHIiUQkCGaQD7Z5A4PDBIPBBIn4D7bwD7ZB/g+vxpn3/YkEJA+2Qf0Pr8aZ9/2JRCQED7ZB/A+vxpn3/Q+2FCSIU/wPtlQkBIhT/YhD/on4iEP/OUwkCHWvg8QMifBbXl9dw5CQkJCQ|V1ZTRTHbRItUJEBFD6/BRo0MhQAAAABFhcl+YUGD6QFFD7bSSYnQQcHpAkqNdIoERQ+2WANBD7ZAAkmDwARIg8EEQQ+vw5lB9/qJx0EPtkD9QQ+vw5lB9/pBicFBD7ZA/ECIefxEiEn9QQ+vw0SIWf+ZQff6iEH+TDnGdbNEidhbXl/DkJCQkJCQkJCQkJCQ")

		
		this.LoadLib("d2d1","dwrite","dwmapi","gdiplus")
		gsi := buffer(24,0)
		NumPut("uint", 1, gsi, 0)
		token := 0
		DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", gsi, "Ptr*", 0)
		this.gdiplusToken := token
		this._guid("{06152247-6f50-465a-9245-118bfd3b6007}",&clsidFactory)
		this._guid("{b859ee5a-d838-4b5b-a2e8-1adc7d93db48}",&clsidwFactory)

		this.gui := Gui("-DPIScale",titleName)
		this.gui.show("x" x " y" y " w" width " h" height)

		this.hwnd := this.gui.hwnd

		this.tBufferPtr := Buffer(4096,0)
		this.rect1Ptr :=  Buffer(64,0)
		this.rect2Ptr :=  Buffer(64,0)
		this.rtPtr :=  Buffer(64,0)
		this.hrtPtr :=  Buffer(64,0)
		this.matrixPtr :=  Buffer(64,0)
		this.colPtr :=  Buffer(64,0)
		this.clrPtr :=  Buffer(64,0)
		
		if (DllCall("d2d1\D2D1CreateFactory","uint",1,"Ptr",clsidFactory,"uint*",0,"Ptr*",&pOut) != 0) {
			this.Err("Problem creating factory","window will not function")
			return
		}	
		this.factory := pOut
		NumPut("float", 1, this.tBufferPtr, 16)
		if (DllCall(this.vTable(this.factory,11),"ptr",this.factory,"ptr",this.tBufferPtr.ptr,"ptr",0,"uint",0,"ptr*",&pOut) != 0) {
			this.Err("Problem creating stroke","window will not function")
			return
		}
		this.stroke := pOut
		NumPut("uint", 2, this.tBufferPtr, 0)
		NumPut("uint", 2, this.tBufferPtr, 4)
		NumPut("uint", 2, this.tBufferPtr, 12)
		NumPut("float", 1, this.tBufferPtr, 16)
		if (DllCall(this.vTable(this.factory,11),"ptr",this.factory,"ptr",this.tBufferPtr.ptr,"ptr",0,"uint",0,"ptr*",&pOut) != 0) {
			this.Err("Problem creating rounded stroke","window will not function")
			return
		}
		this.strokeRounded := pOut
		NumPut("uint", 1, this.rtPtr, 8)
		NumPut("float", 96, this.rtPtr, 12)
		NumPut("float", 96, this.rtPtr, 16)
		NumPut("Ptr", this.hwnd, this.hrtPtr, 0)
		NumPut("uint", width, this.hrtPtr, a_ptrsize)
		NumPut("uint", height, this.hrtPtr,a_ptrsize+4)
		NumPut("uint", (vsync?0:2), this.hrtPtr, a_ptrsize+8)
		if (DllCall(this.vTable(this.factory,14),"Ptr",this.factory,"Ptr",this.rtPtr,"ptr",this.hrtPtr,"Ptr*",&pOut) != 0) {
			this.Err("Problem creating renderTarget","window will not function")
			return
		}
		this.renderTarget := pOut
		NumPut("float", 1, this.matrixPtr, 0)
		this.SetIdentity(4)
		if (DllCall(this.vTable(this.renderTarget,8),"Ptr",this.renderTarget,"Ptr",this.colPtr,"Ptr",this.matrixPtr,"Ptr*",&pOut) != 0) {
			this.Err("Problem creating brush","window will not function")
			return
		}
		this.SetPosition(,,width,height)
		this.brush := pOut
		DllCall(this.vTable(this.renderTarget,32),"Ptr",this.renderTarget,"Uint",1)
		if (DllCall("dwrite\DWriteCreateFactory","uint",0,"Ptr",clsidwFactory,"Ptr*",&pOut) != 0) {
			this.Err("Problem creating writeFactory","window will not function")
			return
		}
		this.wFactory := pOut
		
		this.SetClearColor()
		
		DllCall(this.vTable(this.renderTarget,48),"Ptr",this.renderTarget)
		DllCall(this.vTable(this.renderTarget,47),"Ptr",this.renderTarget,"Ptr",this.clrPtr)
		DllCall(this.vTable(this.renderTarget,49),"Ptr",this.renderTarget,"int64*",&pOut,"int64*",&pOut)
		
		OnMessage(0x200,this.WM_MOUSEMOVE.Bind(this))
		OnMessage(0x201,this.WM_LBUTTONDOWN.Bind(this))
		OnMessage(0x203,this.WM_LBUTTONDOWN.Bind(this))
		OnMessage(0x207,this.WM_MBUTTONDOWN.Bind(this))
		OnMessage(0x209,this.WM_MBUTTONDOWN.Bind(this))
		OnMessage(0x204,this.WM_RBUTTONDOWN.Bind(this))
		OnMessage(0x206,this.WM_RBUTTONDOWN.Bind(this))
		OnMessage(0x14,this.WM_ERASEBKGND.Bind(this))
		OnMessage(0x5,this.WM_SIZE.Bind(this))
		OnMessage(0x2A3,this.WM_MOUSELEAVE.Bind(this))
		OnMessage(0x232,this.WM_EXITSIZEMOVE.Bind(this))
		OnMessage(0x18,this.WM_SHOWWINDOW.Bind(this))
		
		DllCall("QueryPerformanceFrequency", "Int64*", &pOut)
		this.deltaFreq := pOut
		DllCall("QueryPerformanceCounter", "Int64*", &pOut)
		this.deltaLast := pOut
	}
	
	
	;####################################################################################################################################################################################################################################
	;BeginDraw
	;
	;return				;				True (for now)
	;
	;Notes				;				Must always call EndDraw to finish drawing and update the window
	
	BeginDraw(clear:=1) {
		local pOut:=0
		
		if (this.sizeChangeReady) {
			if (this.SetPosition(-1,-1,this.newWidth,this.newHeight))
				this.sizeChangeReady := 0
		}
		
		DllCall(this.vTable(this.renderTarget,48),"Ptr",this.renderTarget)
		if (clear)	
			DllCall(this.vTable(this.renderTarget,47),"Ptr",this.renderTarget,"Ptr",this.clrPtr)
		
		DllCall("QueryPerformanceCounter", "Int64*", &pOut)
		this.deltaTime := (pOut-this.deltaLast) / this.deltaFreq ;* 1000
		this.deltaLast := pOut
		
		this.timeScale := this.deltaTime * this.gameSpeed
		
		this.deltaTotal += this.deltaTime
		this.frameSum += this.deltaTime
		if (this.frameSum > 0.999999) {
			this.frameSum := 0
			this.fps := this.frames
			this.frames := 0
		}
		this.frames++

		this.lbutton := this.clicks & 0x1
		this.mbutton := (this.clicks >>1) & 0x1
		this.rbutton := (this.clicks >>2) & 0x1
		this.clicks := 0
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;EndDraw
	;
	;return				;				Void
	;
	;Notes				;				Must always call EndDraw to finish drawing and update the window
	
	EndDraw() {
		local pOut:=0
		DllCall(this.vTable(this.renderTarget,49),"Ptr",this.renderTarget,"int64*",&pOut,"int64*",&pOut)
		if (this.iconic)
			sleep 10
	}
	
	
	;####################################################################################################################################################################################################################################
	;SetClearColor
	;
	;return				;				Void
	;
	;Notes				;				The color that is used to clear the backgroun
	
	SetClearColor(color:=0x222222) {
		NumPut("float", ((color & 0xFF0000)>>16)/255, this.clrPtr, 0)
		NumPut("float", ((color & 0xFF00)>>8)/255,this.clrPtr,4)
		NumPut("float", ((color & 0xFF))/255, this.clrPtr, 8)
		NumPut("float", 1, this.clrPtr, 12)
		DllCall(this.vTable(this.brush,8),"Ptr",this.brush,"Ptr",this.clrPtr)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawImage
	;
	;dstX				:				X position to draw to
	;dstY				:				Y position to draw to
	;dstW				:				Width of image to draw to
	;dstH				:				Height of image to draw to
	;srcX				:				X position to draw from
	;srcY				:				Y position to draw from
	;srcW				:				Width of image to draw from
	;srcH				:				Height of image to draw from
	;alpha				:				Image transparency, float between 0 and 1
	;drawCentered		:				Draw the image centered on dstX/dstY, otherwise dstX/dstY will be the top left of the image
	;rotation			:				Image rotation in degrees (0-360)
	;rotationOffsetX	:				X offset to base rotations on (defaults to center x)
	;rotationOffsetY	:				Y offset to base rotations on (defaults to center y)
	;
	;return				;				Void
	
	DrawImage(image,dstX,dstY,dstW:=0,dstH:=0,srcX:=0,srcY:=0,srcW:=0,srcH:=0,alpha:=1,drawCentered:=0,rotation:=0,rotOffX:=0,rotOffY:=0) {
		i := (this.imageCache.Has(image) ? this.imageCache[image] : this.cacheImage(image))
		
		if (dstW <= 0)
			dstW := i["w"]
		if (dstH <= 0)
			dstH := i["h"]
		x := dstX-(drawCentered?dstW/2:0)
		y := dstY-(drawCentered?dstH/2:0)
		NumPut("float", x, this.rect1Ptr, 0)
		NumPut("float", y, this.rect1Ptr, 4)
		NumPut("float", x + dstW, this.rect1Ptr, 8)
		NumPut("float", y + dstH, this.rect1Ptr, 12)
		NumPut("float", srcX, this.rect2Ptr, 0)
		NumPut("float", srcY,this.rect2Ptr,4)
		NumPut("float", srcX + (srcW=0?i["w"]:srcW),this.rect2Ptr,8)
		NumPut("float", srcY + (srcH=0?i["h"]:srcH),this.rect2Ptr,12)
		
		if (rotation != 0) {
			if (this.bits) {
				if (rotOffX or rotOffY) {
					NumPut("float", dstX+rotOffX, this.tBufferPtr, 0)
					NumPut("float", dstY+rotOffY,this.tBufferPtr,4)
				} else {
					NumPut("float", dstX+(drawCentered?0:dstW/2), this.tBufferPtr, 0)
					NumPut("float", dstY+(drawCentered?0:dstH/2), this.tBufferPtr, 4)
				}
				DllCall("d2d1\D2D1MakeRotateMatrix","float",rotation,"double",NumGet(this.tBufferPtr,0,"double"),"ptr",this.matrixPtr)
			} else {
				DllCall("d2d1\D2D1MakeRotateMatrix","float",rotation,"float",dstX+(drawCentered?0:dstW/2),"float",dstY+(drawCentered?0:dstH/2),"ptr",this.matrixPtr)
			}
			DllCall(this.vTable(this.renderTarget,30),"ptr",this.renderTarget,"ptr",this.matrixPtr)
			DllCall(this.vTable(this.renderTarget,26),"ptr",this.renderTarget,"ptr",i["p"],"ptr",this.rect1Ptr,"float",alpha,"uint",this.interpolationMode,"ptr",this.rect2Ptr)
			this.SetIdentity()
			DllCall(this.vTable(this.renderTarget,30),"ptr",this.renderTarget,"ptr",this.matrixPtr)
		} else {
			DllCall(this.vTable(this.renderTarget,26),"ptr",this.renderTarget,"ptr",i["p"],"ptr",this.rect1Ptr,"float",alpha,"uint",this.interpolationMode,"ptr",this.rect2Ptr)
		}
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawText
	;
	;text				:				The text to be drawn
	;x					:				X position
	;y					:				Y position
	;size				:				Size of font
	;color				:				Color of font
	;fontName			:				Font name (must be installed)
	;extraOptions		:				Additonal options which may contain any of the following seperated by spaces:
	;									Width .............	w[number]				: Example > w200			(Default: this.width)
	;									Height ............	h[number]				: Example > h200			(Default: this.height)
	;									Alignment ......... a[Left/Right/Center]	: Example > aCenter			(Default: Left)
	;									DropShadow ........	ds[hex color]			: Example > dsFF000000		(Default: DISABLED)
	;									DropShadowXOffset . dsx[number]				: Example > dsx2			(Default: 1)
	;									DropShadowYOffset . dsy[number]				: Example > dsy2			(Default: 1)
	;									Outline ........... ol[hex color]			: Example > olFF000000		(Default: DISABLED)
	;
	;return				;				Void
	
	DrawText(text,x,y,size:=18,color:=0xFFFFFFFF,fontName:="Arial",extraOptions:="") {
		local w,h,p,ds,dsx,dsy,ol
		w := (RegExMatch(extraOptions,"w([\d\.]+)",&w) ? w[1] : this.width)
		h := (RegExMatch(extraOptions,"h([\d\.]+)",&h) ? h[1] : this.height)
		
		p := (this.fonts.Has(fontName size) ? this.fonts[fontName size] : this.CacheFont(fontName,size))
		
		DllCall(this.vTable(p,3),"ptr",p,"uint",(InStr(extraOptions,"aRight") ? 1 : InStr(extraOptions,"aCenter") ? 2 : 0))
		
		if (RegExMatch(extraOptions,"ds([a-fA-F\d]+)",&ds)) {
			dsx := (RegExMatch(extraOptions,"dsx([\d\.]+)",&dsx) ? dsx[1] : 1)
			dsy := (RegExMatch(extraOptions,"dsy([\d\.]+)",&dsy) ? dsy[1] : 1)
			this.DrawTextShadow(p,text,x+dsx,y+dsy,w,h,"0x" ds[1])
		} else if (RegExMatch(extraOptions,"ol([a-fA-F\d]+)",&ol)) {
			this.DrawTextOutline(p,text,x,y,w,h,"0x" ol[1])
		}
		
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", x+w, this.tBufferPtr, 8)
		NumPut("float", y+h, this.tBufferPtr, 12)
		
		DllCall(this.vTable(this.renderTarget,27),"ptr",this.renderTarget,"wstr",text,"uint",strlen(text),"ptr",p,"ptr",this.tBufferPtr,"ptr",this.brush,"uint",0,"uint",0)
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetTextMetrics
	;
	;text				:				The text to get the metrics of
	;size				:				Font size to measure with
	;fontName			:				Name of the font to use
	;maxWidth			:				Max width (smaller width may cause wrapping)
	;maxHeight			:				Max Height
	;
	;return				;				An array containing width, height and line count of the string
	;
	;Notes				;				Used to measure a string before drawing it
	
	GetTextMetrics(text,size,fontName,maxWidth:=5000,maxHeight:=5000) {
		local layout := 0
		p := (this.fonts.Has(fontName size) ? this.fonts[fontName size] : this.CacheFont(fontName,size))
		DllCall(this.vTable(this.wFactory,18),"ptr",this.wFactory,"WStr",text,"uint",strlen(text),"Ptr",p,"float",maxWidth,"float",maxHeight,"Ptr*",&layout)
		DllCall(this.vTable(layout,60),"ptr",layout,"ptr",this.tBufferPtr,"uint")
		
		w := numget(this.tBufferPtr,8,"float")
		h := numget(this.tBufferPtr,16,"float")
		DllCall(this.vTable(layout,2),"ptr",layout)
		return {w:w,width:w,h:h,height:h,lines:numget(this.tBufferPtr,32,"uint")}
		
	}
	
	
	;####################################################################################################################################################################################################################################
	;SetTextRenderParams
	;
	;gamma				:				Gamma value ................. (1 > 256)
	;contrast			:				Contrast value .............. (0.0 > 1.0)
	;clearType			:				Clear type level ............ (0.0 > 1.0)
	;pixelGeom			:				
	;									0 - DWRITE_PIXEL_GEOMETRY_FLAT
    ;									1 - DWRITE_PIXEL_GEOMETRY_RGB
    ;									2 - DWRITE_PIXEL_GEOMETRY_BGR
	;
	;renderMode			:				
    ; 									0 - DWRITE_RENDERING_MODE_DEFAULT
    ; 									1 - DWRITE_RENDERING_MODE_ALIASED
    ; 									2 - DWRITE_RENDERING_MODE_GDI_CLASSIC
    ; 									3 - DWRITE_RENDERING_MODE_GDI_NATURAL
    ; 									4 - DWRITE_RENDERING_MODE_NATURAL
    ; 									5 - DWRITE_RENDERING_MODE_NATURAL_SYMMETRIC
    ; 									6 - DWRITE_RENDERING_MODE_OUTLINE
	;									7 - DWRITE_RENDERING_MODE_CLEARTYPE_GDI_CLASSIC
	;									8 - DWRITE_RENDERING_MODE_CLEARTYPE_GDI_NATURAL
	;									9 - DWRITE_RENDERING_MODE_CLEARTYPE_NATURAL
	;									10 - DWRITE_RENDERING_MODE_CLEARTYPE_NATURAL_SYMMETRIC
	;
	;return				;				Void
	;
	;Notes				;				Used to affect how text is rendered
	
	SetTextRenderParams(gamma:=1,contrast:=0,cleartype:=1,pixelGeom:=0,renderMode:=0) {
		local params := 0
		DllCall(this.vTable(this.wFactory,12),"ptr",this.wFactory,"Float",gamma,"Float",contrast,"Float",cleartype,"Uint",pixelGeom,"Uint",renderMode,"Ptr*",&params)
		DllCall(this.vTable(this.renderTarget,36),"Ptr",this.renderTarget,"Ptr",params)
	}
	
	
	;####################################################################################################################################################################################################################################
	;InstallFont
	;
	;fontPath			:				A string containing a path to the font file
	;
	;return				;				Number of fonts added
	;
	;Notes				;				Allows using custom fonts from a suported file (WARNING: Currently the fonts will be installed on the system
	;									even after the program closes, private fonts seem to be incompatible with d2d)
	;									Supported font extensions, .fon .fnt .ttf .ttc .fot .otf .mmm .pfb .pfm
	;									May need to be called before instancing a class
	
	InstallFont(fontPath) {
		return DllCall("Gdi32\AddFontResourceEx","Str",fontPath,"Uint",0x20,"Uint",0) ;FR_PRIVATE doesn't work, not sure why, a more in depth solution later
	}
	
	
	
	;####################################################################################################################################################################################################################################
	;DrawEllipse
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of ellipse
	;h					:				Height of ellipse
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawEllipse(x, y, w, h, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", w, this.tBufferPtr, 8)
		NumPut("float", h, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,20),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillEllipse
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of ellipse
	;h					:				Height of ellipse
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillEllipse(x, y, w, h, color) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", w, this.tBufferPtr, 8)
		NumPut("float", h, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,21),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawCircle
	;
	;x					:				X position
	;y					:				Y position
	;radius				:				Radius of circle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawCircle(x, y, radius, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", radius, this.tBufferPtr, 8)
		NumPut("float", radius, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,20),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillCircle
	;
	;x					:				X position
	;y					:				Y position
	;radius				:				Radius of circle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillCircle(x, y, radius, color) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", radius, this.tBufferPtr, 8)
		NumPut("float", radius, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,21),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawRectangle(x, y, w, h, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", x+w, this.tBufferPtr, 8)
		NumPut("float", y+h, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,16),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillRectangle(x, y, w, h, color) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", x+w, this.tBufferPtr, 8)
		NumPut("float", y+h, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,17),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawRoundedRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;radiusX			:				The x-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;radiusY			:				The y-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void
	
	DrawRoundedRectangle(x, y, w, h, radiusX, radiusY, color, thickness:=1) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", x+w, this.tBufferPtr, 8)
		NumPut("float", y+h, this.tBufferPtr, 12)
		NumPut("float", radiusX, this.tBufferPtr, 16)
		NumPut("float", radiusY, this.tBufferPtr, 20)
		DllCall(this.vTable(this.renderTarget,18),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush,"float",thickness,"ptr",this.stroke)
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillRectangle
	;
	;x					:				X position
	;y					:				Y position
	;w					:				Width of rectangle
	;h					:				Height of rectangle
	;radiusX			:				The x-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;radiusY			:				The y-radius for the quarter ellipse that is drawn to replace every corner of the rectangle.
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;
	;return				;				Void
	
	FillRoundedRectangle(x, y, w, h, radiusX, radiusY, color) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", x+w, this.tBufferPtr, 8)
		NumPut("float", y+h, this.tBufferPtr, 12)
		NumPut("float", radiusX, this.tBufferPtr, 16)
		NumPut("float", radiusY, this.tBufferPtr, 20)
		DllCall(this.vTable(this.renderTarget,19),"Ptr",this.renderTarget,"Ptr",this.tBufferPtr,"ptr",this.brush)
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawLine
	;
	;x1					:				X position for line start
	;y1					:				Y position for line start
	;x2					:				X position for line end
	;y2					:				Y position for line end
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;
	;return				;				Void

	DrawLine(x1,y1,x2,y2,color:=0xFFFFFFFF,thickness:=1,rounded:=0) {
		this.SetBrushColor(color)
		if (this.bits) {
			NumPut("float", x1, this.tBufferPtr, 0)  ;Special thanks to teadrinker for helping me
			NumPut("float", y1, this.tBufferPtr, 4)  ;with these params!
			NumPut("float", x2, this.tBufferPtr, 8)
			NumPut("float", y2, this.tBufferPtr, 12)
			DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"Double",NumGet(this.tBufferPtr,0,"double"),"Double",NumGet(this.tBufferPtr,8,"double"),"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
		} else {
			DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"float",x1,"float",y1,"float",x2,"float",y2,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
		}
		
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawLines
	;
	;lines				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;connect			:				If 1 then connect the start and end together
	;thickness			:				Thickness of the line
	;
	;return				;				1 on success; 0 otherwise

	DrawLines(points,color,connect:=0,thickness:=1,rounded:=0) {
		if (points.length() < 2)
			return 0
		lx := sx := points[1][1]
		ly := sy := points[1][2]
		this.SetBrushColor(color)
		if (this.bits) {
			loop points.length()-1 {
				NumPut("float", lx, this.tBufferPtr, 0), NumPut("float", ly, this.tBufferPtr, 4), NumPut("float", lx:=points[a_index+1][1], this.tBufferPtr, 8), NumPut("float", ly:=points[a_index+1][2], this.tBufferPtr, 12)
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"Double",NumGet(this.tBufferPtr,0,"double"),"Double",NumGet(this.tBufferPtr,8,"double"),"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
			}
			if (connect) {
				NumPut("float", sx, this.tBufferPtr, 0), NumPut("float", sy, this.tBufferPtr, 4), NumPut("float", lx, this.tBufferPtr, 8), NumPut("float", ly, this.tBufferPtr, 12)
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"Double",NumGet(this.tBufferPtr,0,"double"),"Double",NumGet(this.tBufferPtr,8,"double"),"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
			}
		} else {
			loop points.length()-1 {
				x1 := lx
				y1 := ly
				x2 := lx := points[a_index+1][1]
				y2 := ly := points[a_index+1][2]
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"float",x1,"float",y1,"float",x2,"float",y2,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
			}
			if (connect)
				DllCall(this.vTable(this.renderTarget,15),"Ptr",this.renderTarget,"float",sx,"float",sy,"float",lx,"float",ly,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke))
		}
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;DrawPolygon
	;
	;points				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;thickness			:				Thickness of the line
	;xOffset			:				X offset to draw the polygon array
	;yOffset			:				Y offset to draw the polygon array
	;
	;return				;				1 on success; 0 otherwise

	DrawPolygon(points,color,thickness:=1,rounded:=0,xOffset:=0,yOffset:=0) {
		if (points.length() < 3)
			return 0
		
		if (DllCall(this.vTable(this.factory,10),"Ptr",this.factory,"Ptr*",&pGeom) = 0) {
			if (DllCall(this.vTable(pGeom,17),"Ptr",pGeom,"Ptr*",&sink) = 0) {
				this.SetBrushColor(color)
				if (this.bits) {
					NumPut("float", points[1][1]+xOffset, this.tBufferPtr, 0)
					NumPut("float", points[1][2]+yOffset, this.tBufferPtr, 4)
					DllCall(this.vTable(sink,5),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"),"uint",1)
					loop points.length()-1
					{
						NumPut("float", points[a_index+1][1]+xOffset, this.tBufferPtr, 0)
						NumPut("float", points[a_index+1][2]+yOffset, this.tBufferPtr, 4)
						DllCall(this.vTable(sink,10),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"))
					}
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				} else {
					DllCall(this.vTable(sink,5),"ptr",sink,"float",points[1][1]+xOffset,"float",points[1][2]+yOffset,"uint",1)
					loop points.length()-1
						DllCall(this.vTable(sink,10),"ptr",sink,"float",points[a_index+1][1]+xOffset,"float",points[a_index+1][2]+yOffset)
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				}
				
				if (DllCall(this.vTable(this.renderTarget,22),"Ptr",this.renderTarget,"Ptr",pGeom,"ptr",this.brush,"float",thickness,"ptr",(rounded?this.strokeRounded:this.stroke)) = 0) {
					DllCall(this.vTable(sink,2),"ptr",sink)
					DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
					return 1
				}
				DllCall(this.vTable(sink,2),"ptr",sink)
				DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
			}
		}
		
		
		return 0
	}
	
	
	;####################################################################################################################################################################################################################################
	;FillPolygon
	;
	;points				:				An array of 2d points, example: [[0,0],[5,0],[0,5]]
	;color				:				Color in 0xAARRGGBB or 0xRRGGBB format (if 0xRRGGBB then alpha is set to FF (255))
	;xOffset			:				X offset to draw the filled polygon array
	;yOffset			:				Y offset to draw the filled polygon array
	;
	;return				;				1 on success; 0 otherwise

	FillPolygon(points,color,xoffset:=0,yoffset:=0) {
		if (points.length() < 3)
			return 0
		
		if (DllCall(this.vTable(this.factory,10),"Ptr",this.factory,"Ptr*",&pGeom) = 0) {
			if (DllCall(this.vTable(pGeom,17),"Ptr",pGeom,"Ptr*",&sink) = 0) {
				this.SetBrushColor(color)
				if (this.bits) {
					NumPut("float", points[1][1]+xoffset, this.tBufferPtr, 0)
					NumPut("float", points[1][2]+yoffset, this.tBufferPtr, 4)
					DllCall(this.vTable(sink,5),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"),"uint",0)
					loop points.length()-1
					{
						NumPut("float", points[a_index+1][1]+xoffset, this.tBufferPtr, 0)
						NumPut("float", points[a_index+1][2]+yoffset, this.tBufferPtr, 4)
						DllCall(this.vTable(sink,10),"ptr",sink,"double",numget(this.tBufferPtr,0,"double"))
					}
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				} else {
					DllCall(this.vTable(sink,5),"ptr",sink,"float",points[1][1]+xoffset,"float",points[1][2]+yoffset,"uint",0)
					loop points.length()-1
						DllCall(this.vTable(sink,10),"ptr",sink,"float",points[a_index+1][1]+xoffset,"float",points[a_index+1][2]+yoffset)
					DllCall(this.vTable(sink,8),"ptr",sink,"uint",1)
					DllCall(this.vTable(sink,9),"ptr",sink)
				}
				
				if (DllCall(this.vTable(this.renderTarget,23),"Ptr",this.renderTarget,"Ptr",pGeom,"ptr",this.brush,"ptr",0) = 0) {
					DllCall(this.vTable(sink,2),"ptr",sink)
					DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
					return 1
				}
				DllCall(this.vTable(sink,2),"ptr",sink)
				DllCall(this.vTable(pGeom,2),"Ptr",pGeom)
				
			}
		}
		
		
		return 0
	}
	
	
	;####################################################################################################################################################################################################################################
	;SetPosition
	;
	;x					:				X position to move the window to (screen space)
	;y					:				Y position to move the window to (screen space)
	;w					:				New Width
	;h					:				New Height
	;
	;return				;				1 on succes, 0 otherwise
	;
	;notes				:				Only used when not attached to a window
	
	SetPosition(x:=-1,y:=-1,w:=0,h:=0) {
		move := 0
		w := (w < this.minWidth ? this.minWidth : w)
		h := (h < this.minHeight ? this.minHeight : h)
		if (w > 0 and h > 0 and (w!=this.width or h!=this.height)) {
			move := 1
			newSize := Buffer(16,0)
			NumPut("uint", this.width := w, newSize, 0)
			NumPut("uint", this.height := h, newSize, 4)
			if (DllCall(this.vTable(this.renderTarget,58),"Ptr",this.renderTarget,"ptr",newsize) != 0) {
				return 0
			}
		}
		if (x != -1 and y != -1) {
			this.x := x, this.y := y, move := 1
		}
		
		this.x := x
		this.y := y
		if (move and DllCall("MoveWindow","Ptr",this.hwnd,"int",x,"int",y,"int",this.width,"int",this.height,"char",1) != 0)
			return 0
		return 1
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetImageDimensions
	;
	;image				:				Image file name
	;&w					:				Width of image
	;&h					:				Height of image
	;
	;return				;				Void
	
	GetImageDimensions(image, &w, &h) {
		local i
		i := (this.imageCache.Has(image) ? this.imageCache[image] : this.cacheImage(image))
		w := i["w"]
		h := i["h"]
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetMousePos
	;
	;&x					:				X position of mouse to return
	;&y					:				Y position of mouse to return
	;realRegionOnly		:				Return 1 only if in the real region, which does not include the invisible borders, (client area does not have borders)
	;
	;return				;				Returns 1 if mouse within window/client region; 0 otherwise
	;
	;notes				:				Legacy function, may be useful in some situations though
	
	GetMousePos(&x, &y) {
		if (!DllCall("GetCursorPos","ptr",this.tBufferPtr))
			return 0
		if (!DllCall("ScreenToClient","ptr",this.hwnd,"ptr",this.tBufferPtr))
			return 0
		x := NumGet(this.tBufferPtr,0,"int")
		y := NumGet(this.tBufferPtr,4,"int")
		inside := (x >= 0 and y >= 0 and x <= this.width and y <= this.height)
		return inside
	}
	
	
	;####################################################################################################################################################################################################################################
	;Clear
	;
	;notes						:			Clears the screen, essentially the same as running BegindDraw followed by EndDraw
	
	Clear() {
		DllCall(this.vTable(this.renderTarget,48),"Ptr",this.renderTarget)
		DllCall(this.vTable(this.renderTarget,47),"Ptr",this.renderTarget,"Ptr",this.clrPtr)
		DllCall(this.vTable(this.renderTarget,49),"Ptr",this.renderTarget,"int64*",&tag1,"int64*",&tag2)
	}
	
	
	;####################################################################################################################################################################################################################################
	;GetDistance
	;
	;x1							:			x position of point 1
	;y1							:			y position of point 1
	;x2							:			x position of point 2
	;y2							:			y position of point 2
	;
	;Return						;			distance between the 2 points
	;
	;notes						:			Simple distance calculations between 2 points
	
	
	GetDistance(x1,y1,x2,y2) {
		x:=x1-x2
		y:=y1-y2
		return sqrt((x*x) + (y*y))
	}
	
	
	;####################################################################################################################################################################################################################################
	;MouseInRegion
	;
	;x1							:			X position of top left
	;y1							:			Y position of top left
	;x2							:			X position of bottom right
	;y2							:			Y position of bottom right
	;
	;Return						;			Returns true if mouse is within region; 0 otherwise
	
	
	MouseInRegion(x1,y1,x2,y2) {
		return (this.mouseX >= x1 and this.mouseX <= x2 and this.mouseY >= y1 and this.mouseY <= y2)
	}	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	;########################################## 
	;  internal functions used by the class
	;########################################## 
	SetIdentity(o:=0) {
		NumPut("float", 1, this.matrixPtr, o+0)
		NumPut("float", 0, this.matrixPtr, o+4)
		NumPut("float", 0, this.matrixPtr, o+8)
		NumPut("float", 1, this.matrixPtr, o+12)
		NumPut("float", 0, this.matrixPtr, o+16)
		NumPut("float", 0, this.matrixPtr, o+20)
	}
	DrawTextShadow(p,text,x,y,w,h,color) {
		this.SetBrushColor(color)
		NumPut("float", x, this.tBufferPtr, 0)
		NumPut("float", y, this.tBufferPtr, 4)
		NumPut("float", x+w, this.tBufferPtr, 8)
		NumPut("float", y+h, this.tBufferPtr, 12)
		DllCall(this.vTable(this.renderTarget,27),"ptr",this.renderTarget,"wstr",text,"uint",strlen(text),"ptr",p,"ptr",this.tBufferPtr,"ptr",this.brush,"uint",0,"uint",0)
	}
	DrawTextOutline(p,text,x,y,w,h,color) {
		static o := [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]
		this.SetBrushColor(color)
		for k,v in o
		{
			NumPut("float", x+v[1], this.tBufferPtr, 0)
			NumPut("float", y+v[2], this.tBufferPtr, 4)
			NumPut("float", x+w+v[1], this.tBufferPtr, 8)
			NumPut("float", y+h+v[2], this.tBufferPtr, 12)
			DllCall(this.vTable(this.renderTarget,27),"ptr",this.renderTarget,"wstr",text,"uint",strlen(text),"ptr",p,"ptr",this.tBufferPtr,"ptr",this.brush,"uint",0,"uint",0)
		}
	}
	Err(str*) {
		s := ""
		for k,v in str
			s .= (s = "" ? "" : "`n`n") v
		msgbox 0x30 | 0x1000, "Problem!", s
	}
	LoadLib(lib*) {
		for k,v in lib
			if (!DllCall("GetModuleHandle", "str", v, "Ptr"))
				DllCall("LoadLibrary", "Str", v) 
	}
	SetBrushColor(col) {
		if (col <= 0xFFFFFF)
			col += 0xFF000000
		if (col != this.lastCol) {
			NumPut("Float",((col & 0xFF0000)>>16)/255,this.colPtr,0)
			NumPut("Float",((col & 0xFF00)>>8)/255,this.colPtr,4)
			NumPut("Float",((col & 0xFF))/255,this.colPtr,8)
			NumPut("Float",(col > 0xFFFFFF ? ((col & 0xFF000000)>>24)/255 : 1),this.colPtr,12)
			DllCall(this.vTable(this.brush,8),"Ptr",this.brush,"Ptr",this.colPtr)
			this.lastCol := col
			return 1
		}
		return 0
	}
	vTable(a,p) {
		return NumGet(NumGet(a+0,0,"ptr"),p*a_ptrsize,"Ptr")
	}
	_guid(guidStr,&clsid) {
		clsid := buffer(16,0)
		DllCall("ole32\CLSIDFromString", "WStr", guidStr, "Ptr", clsid)
	}
	SetVarCapacity(key,size,fill:=0) {
		this.SetCapacity(key,size)
		DllCall("RtlFillMemory","Ptr",this.GetAddress(key),"Ptr",size,"uchar",fill)
		return this.GetAddress(key)
	}
	CacheImage(image) {
		if (this.imageCache.has(image))
			return 1
		if (image = "") {
			this.Err("Error, expected resource image path but empty variable was supplied!")
			return 0
		}
		if (!FileExist(image)) {
			this.Err("Error finding resource image","'" image "' does not exist!")
			return 0
		}
		w := h := bm := bitmap := 0
		DllCall("gdiplus\GdipCreateBitmapFromFile", "Str", image, "Ptr*", &bm)
		DllCall("gdiplus\GdipGetImageWidth", "Ptr", bm, "Uint*", &w)
		DllCall("gdiplus\GdipGetImageHeight", "Ptr", bm, "Uint*", &h)
		r := buffer(16,0)
		NumPut("uint", w, r, 8)
		NumPut("uint", h, r, 12)
		bmdata := buffer(32,0)
		ret := DllCall("Gdiplus\GdipBitmapLockBits", "Ptr", bm, "Ptr", r, "uint", 3, "int", 0x26200A, "Ptr", bmdata)
		scan := NumGet(bmdata, 16, "Ptr")
		p := DllCall("GlobalAlloc", "uint", 0x40, "ptr", 16+((w*h)*4), "ptr")
		DllCall(this._cacheImage,"Ptr",p,"Ptr",scan,"int",w,"int",h,"uchar",255,"int")
		DllCall("Gdiplus\GdipBitmapUnlockBits", "Ptr", bm, "Ptr", bmdata)
		DllCall("gdiplus\GdipDisposeImage", "ptr", bm)
		props := buffer(64,0)
		NumPut("uint", 28, props, 0)
		NumPut("uint",1,props,4)
		if (this.bits) {
			NumPut("uint", w, this.tBufferPtr, 0)
			NumPut("uint", h, this.tBufferPtr, 4)
			if (v := DllCall(this.vTable(this.renderTarget,4),"ptr",this.renderTarget,"int64",NumGet(this.tBufferPtr,0,"int64"),"ptr",p,"uint",4 * w,"ptr",props,"Ptr*",&bitmap) != 0) {
				this.Err("Problem creating D2D bitmap for image '" image "'")
				return 0
			}
		} else {
			if (v := DllCall(this.vTable(this.renderTarget,4),"ptr",this.renderTarget,"uint",w,"uint",h,"ptr",p,"uint",4 * w,"ptr",props,"Ptr*",&bitmap) != 0) {
				this.Err("Problem creating D2D bitmap for image '" image "'")
				return 0
			}
		}
		return this.imageCache[image] := Map("p",bitmap, "w",w, "h",h)
	}
	CacheFont(name,size) {
		local textFormat := 0
		if (DllCall(this.vTable(this.wFactory,15),"ptr",this.wFactory,"wstr",name,"ptr",0,"uint",400,"uint",0,"uint",5,"float",size,"wstr","en-us","Ptr*",&textFormat) != 0) {
			this.Err("Unable to create font: " name " (size: " size ")","Try a different font or check to see if " name " is a valid font!")
			return 0
		}
		return this.fonts[name size] := textFormat
	}
	__Delete() {
		DllCall("gdiplus\GdiplusShutdown", "Ptr*", this.gdiplusToken)
		this.gui.destroy()
	}
	Mcode(str) {
		local pp := 0, op := 0
		s := strsplit(str,"|")
		if (s.length != 2)
			return
		if (!DllCall("crypt32\CryptStringToBinary", "str", s[this.bits+1], "uint", 0, "uint", 1, "ptr", 0, "uint*", &pp, "ptr", 0, "ptr", 0))
			return
		p := DllCall("GlobalAlloc", "uint", 0, "ptr", pp, "ptr")
		if (this.bits)
			DllCall("VirtualProtect", "ptr", p, "ptr", pp, "uint", 0x40, "uint*", &op)
		if (DllCall("crypt32\CryptStringToBinary", "str", s[this.bits+1], "uint", 0, "uint", 1, "ptr", p, "uint*", &pp, "ptr", 0, "ptr", 0))
			return p
		DllCall("GlobalFree", "ptr", p)
	}
	WM_MOUSEMOVE(a,b,*) {
		this.mouseX := b & 0xFFFF
		this.mouseY := b >> 16
		if (!this.mouseInClient) {
			struct := buffer(24,0)
			numput("uint",(this.bits?24:16),struct,0)
			numput("uint",2,struct,4)
			numput("uint",this.hwnd,struct,8)
			DllCall("TrackMouseEvent","ptr",struct)
			this.mouseInClient := 1
		}
	}
	WM_MOUSELEAVE(*) {
		this.mouseInClient := 0
		this.mouseX := -1
		this.mouseY := -1
	}
	WM_LBUTTONDOWN(a,b,*) {
		this.mouseX := b & 0xFFFF
		this.mouseY := b >> 16
		this.clicks |= 1 << 0
	}
	WM_MBUTTONDOWN(a,b,*) {
		this.mouseX := b & 0xFFFF
		this.mouseY := b >> 16
		this.clicks |= 1 << 1
	}
	WM_RBUTTONDOWN(a,b,*) {
		this.mouseX := b & 0xFFFF
		this.mouseY := b >> 16
		this.clicks |= 1 << 2
	}
	WM_ERASEBKGND(*) {
		return false
	}
	WM_SIZE(a,b,*) {
		if (b != 0) {
			this.newWidth := b & 0xFFFF
			this.newHeight := b >> 16
			if (this.maximized or this.iconic) {
				this.sizeChangeReady := 1
				this.maximized := 0
				this.iconic := 0
			}
		}
		if (a=1) {
			this.iconic := 1
			this.maximized := 0
		}
		if (a=2) {
			this.maximized := 1
			this.iconic := 0
			this.sizeChangeReady := 1
		}
	}
	WM_EXITSIZEMOVE(*) {
		if (!this.iconic) {
			this.sizeChangeReady := 1
		}
	}
	WM_SHOWWINDOW(a,*) {
		if (a=0)
			exitapp
	}
}
