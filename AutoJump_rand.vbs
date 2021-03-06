// 作者：523066680 / vicyang
// https://github.com/vicyang/WeChat-JumpGame-Auto
// 2018-01-02
// v1.21 添加随机因素

Delay 1000
Dim x1,y1, x2,y2

Dim screenX, screenY
screenX = GetScreenX()
screenY = GetScreenY()

Dim bgcolor, iter
Dim top, bottom, centx, centy, dist
Randomize ( time() )

// 上一次的 body 坐标, 触屏时间, 初始时间率
Dim prevx, prevy, lastpress, timerate
Dim body
Dim changed

//init timerate
timerate = 1.32

While (1)
    bgcolor = GetPixelColor(100, 360)
    KeepCapture()
    body = findbody()
    
    If body = 1 Then 
        iter = iter + 1
        say "From: " & x1 & "," & y1
        
        If check_bgcolor_change(bgcolor) = 1 Then 
            bgcolor = GetPixelColor(100, 360)
        End If
        
        KeepCapture()
        top = get_topline( x1 )
        If top < 0 
            Exit While
        End If
        say "top = " & top
        
        centx = get_centx( top, x1 )
        If centx < 0 Then 
            Exit While
        End If
        say "centx = " & centx
        
        bottom = get_bottomline( centx, top )
        centy = (top+bottom)/2
        say "bottom = " & bottom
    
        //魔改，如果遇到干扰导致目标点过于接近边界，则y+20
        If (centy - top) < 20 Then 
            say "Too close, y + 50"
            centy = top + 50
        End If
        
        dist = distance(x1, y1, centx, centy)
        say "from: " & x1 & ", " & y1 & " to: " & centx & ", " & centy
        
        ReleaseCapture()
        SnapShot ("/sdcard/Pictures/autojump_" & iter Mod 5 & ".png")
            
        lastpress = press (dist)
    Else
        Exit While
    End If
    
    Delay 1000 + Int(Rnd() * 1500)
    If Int(Rnd() * 5) = 1 Then 
        press(2)
        Delay 200
    End If
    
    If int(Rnd() * 6) = 0 Then
        say "have a rest"
        Delay 3000 + int(rnd()*3)*1000
    End IF
    
    TracePrint "Step: " & iter
    TracePrint ""
    prevx = x1
    prevy = y1
Wend

Function get_topline( body_x )
    Dim execute
    Dim cmp
    Dim color, num
    Dim xleft, xright, halfx, offset, range
    halfx = screenX / 2
    //考虑body和block非常接近的情况
    offset = 30
    
    If body_x > halfx Then 
        xleft = 1
        xright = halfx - offset
        //TracePrint "get_topline: from left side"
    Else 
        xleft = halfx + offset
        xright = screenX
        //TracePrint "get_topline: from right side"
    End If
    
    range = xright - xleft
    
    For y = 600 To 1000 Step 10
        color = GetPixelColor( xleft, y )
        //say "bgcolor: "& color
        
        num = GetColorNum(xleft, y, xright, y, color, 0.95)
        
        //如果相同颜色的数量比预计像素少 6
        If num < (range - 6) Then
            get_topline = y
            
            //精确扫描
            For yy = (y - 10) To y Step 2
                num = GetColorNum(xleft, yy, xright, yy, color, 0.95)
                If num < (range - 2) Then
                    get_topline = yy
                    Exit For
                End If
            Next
            Exit For
        End If
        
        //say "Y: " & y & ", Result: " & cmp
        //Touch 800, y, 100
        //Delay 100
    Next
    
    If cmp = 1 Then 
        get_topline = -1
    End If
End Function

Function get_centx(topline, body_x)
    Dim color, cmp, num
    bgcolor = GetPixelColor(5, topline)
    
    Dim xleft, xright, halfx, xa, xb
    halfx = screenX / 2
    
    If body_x > halfx Then 
        xleft = 1
        xright = halfx
        //TracePrint "get_cenx: from left side"
    Else 
        xleft = halfx + 1
        xright = screenX
        //TracePrint "get_cenx: from right side"
    End If
    
    //大致区域
    For x = xleft To xright Step 10
        num = GetColorNum(x, topline, x + 9, topline, bgcolor, 0.95)
        If num < 9 Then
            xleft = x - 5
            xright = x + 30
            Exit For
        End If
    Next
    
    If xleft < 1 Then 
        xleft = 1
    End If
    
    If xright > screenX Then 
        xright = screenX
    End If
    
//  say "top " & topline
//  say "test xleft " & xleft & ", xright:" & xright
    
    //精细搜索
    get_centx = -1
    For x = xleft To xright Step 1
        cmp = CmpColor(x, topline, bgcolor, 0.95)
        //不匹配时返回 -1
        If cmp = -1 Then
            xa = x
            Exit For
        End If
    Next
    
    num = GetColorNum(xleft, topline, xright, topline, bgcolor, 0.95)
    get_centx = xa + int((xright - xleft + 1 - num) / 2)
    
End Function

Function get_bottomline( centx, top )
    Dim color, cmp, white, leftcmp, leftw, bgwhite
    color = GetPixelColor(centx, top + 20)
    bgwhite = CmpColor(centx, top+20, "FFFFFF", 0.95)
    
    get_bottomline = -1
    
    For y = top+20 to top+500 Step 10
        cmp     = CmpColor(centx, y, color, 0.95)
        leftcmp = CmpColor(centx - 20, y, color, 0.95)
        
        If cmp = -1 Or leftcmp  = -1 Then 
            white = CmpColor(centx, y, "FFFFFF", 0.9)
            leftw = CmpColor(centx - 20, y, "FFFFFF", 0.9)
            
            //如果不是白色(非圆点)，精确范围
            If white = -1 Then
                get_bottomline = y
                //精确搜索
                For yy = (y - 10) To y Step 2
                    cmp = CmpColor(centx, yy, color, 0.95)
                    If cmp = -1 Then 
                        get_bottomline = yy
                        Exit For
                    End If
                Next
                //结束外部 for
                Exit For
            Else 
                //如果 block 主要为白色，且偏左的轮廓非白色，直接判定bottom
                If bgwhite > -1 And leftw = -1 Then 
                    get_bottomline = y
                    Exit For
                End If
            End If
            
        End If
        
    Next
    
End Function

Function check_bgcolor_change(bgcolor)
    check_bgcolor_change = 0
    While (CmpColor(100, 360, bgcolor, 0.98) = -1)
        say "Color changed"
        Delay 3000
        check_bgcolor_change = 1
        Exit While
    Wend
End Function

Function findbody()
    Dim times = 0
    Dim result = -1

    While ( result = -1 )
        FindPic 0,0,0,0,"Attachment:body.png","000000", 3, 0.95, x1, y1
        If x1 > -1 And y1 > -1 Then 
            x1 = x1 + 30
            y1 = y1 + 30
            result = 1
        End If
        
        If times >= 30 Then 
            result = 0
        End If
        
        times = times+1
        Delay 300
        say "find pic again, times: " & times
    Wend
    findbody = result
    
End Function

Function press(delta)
    Dim hold, r
    
    r = 0
    If bottom - top > 50 Then 
        r = Rnd() * 0.1 - 0.05
    End If
    
    hold = int(delta * (timerate + r) )     
    say "Distance: " & int(delta) & ", Delay: " & hold & " rand: " & left(r, 5)
    Touch centx, centy, hold
    Touch 10, 10, 10
    press = hold
End Function

Function distance(x1, y1, x2, y2)
    distance = sqr( (x1-x2)^2 + (y1-y2)^2 )
End Function

Function OnScriptExit()
    Delay 2000
End Function

Sub say(something)
    ShowMessage something
    TracePrint something
End Sub

