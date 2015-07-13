#pragma rtGlobals=1		// Use modern global access method.


//**************************************************
// Kota Miura 020403-9
// followings are programs to process the results of speed measurement.
//written for processing artificially produced sequences.
// original data consist of a unit with measurements from 4 dots with diffferent intensity and 1 region of only noise (total of 5)
// Such unit was done with 5, 10, 20, 30 40, 50, 60 ,70,80 90 100 frames (11 vector fields)
//the results contained 55 points.

// SeperateWavesbyInt(prefix) this function seperates the 55 point wave by intensity. seperates into 5 different waves, each with 11 points.
//

//***************************************************  
Function/s ReturnName(prewavename,suffix)
	 String prewavename,suffix
	 return prewavename+"_"+suffix
END

Function MakeNamedWaves(prefix,number)
	String prefix,Number
	Make/o/N=11 $(ReturnName((prefix+"AVG"),number))
	Make/o/N=11 $(ReturnName((prefix+"AVGsd"),number))
	Make/o/N=11 $(ReturnName((prefix+"AVGpnts"),number))
	Make/o/N=11 $(ReturnName((prefix+"cAVG"),number))
	Make/o/N=11 $(ReturnName((prefix+"cAVGpnts"),number))	
END

Function/s getnumber(number)
	Variable number
	switch(number)	
		case 0:		
			return num2str(0)
			break						
		case 1:		
			return num2str(100)
			break						
		case 2:		
			return num2str(200)
			break						
		case 3:		
			return num2str(240)
			break						
		case 4:		
			return "Nan"
			break						

		default:						
			break					
	endswitch
END	

Function SeperateWavesbyInt(prefix)
	String Prefix
	String AVG=Prefix+"AVG"
	String AVGsd=Prefix+"AVGsd"
	String AVGpnts=Prefix+"AVGpnts"
	String cAVG=Prefix+"cAVG"
	String cAVGpnts=Prefix+"cAVGpnts"
	wave AVGwave=$AVG
	wave AVGsdwave=$AVGsd
	wave AVGpntswave=$AVGpnts
	wave cAVGwave=$cAVG
	wave cAVGpntswave=$cAVGpnts

	wave/z dotintensity

	MakeNamedWaves(Prefix,num2str(0))
	MakeNamedWaves(Prefix,num2str(100))
	MakeNamedWaves(Prefix,num2str(200))
	MakeNamedWaves(Prefix,num2str(240))
	MakeNamedWaves(Prefix,"Nan")

	Variable j
	String number
	for (j=0;j<5;j+=1)
		number=getnumber(j)
		wave/z AVGnum=$(ReturnName(AVG,number))
		wave/z AVGsdnum=$(ReturnName(AVGsd,number))
		wave/z AVGpntsnum=$(ReturnName(AVGpnts,number))
		wave/z cAVGnum=$(ReturnName(cAVG,number))
		wave/z cAVGpntsnum=$(ReturnName(cAVGpnts,number))	
		Variable V_number
		if (j<4)
		 	V_number=str2num(number)
		 else
		 	V_number=999
		 endif
		Variable i,k
		k=0
		for (i=0;i<55;i+=1)
			if (dotintensity[i]==V_number)
				AVGnum[k]=AVGwave[i]
				AVGsdnum[k]=AVGsdwave[i]
				AVGpntsnum[k]=AVGpntswave[i]
				cAVGnum[k]=cAVGwave[i]
				cAVGpntsnum[k]=cAVGpntswave[i]
				k+=1
			endif	
		endfor
	endfor
END
		
Macro DOseperation(prefix)
	String prefix
	SeperateWavesbyInt(prefix)
END

//***********

Function/s RetrievePrifix(speed,diameter)
	String Speed
	Variable diameter
	return ("dot"+num2str(diameter)+"V"+speed)	
END

Function GetDiameter(i)
	Variable i
	switch(i)	
		case 0:		
			return 1
			break						
		case 1:		
			return 4
			break						
		case 2:		
			return 10
			break						
		default:						
			break					
	endswitch
	
END

Function getcolor(number)
	Variable number
	switch(number)	
		case 0:		
			return 0
			break						
		case 1:		
			return 17408
			break						
		case 2:		
			return 34816
			break						
		case 3:		
			return 0
			break						
		case 4:		
			return 0
			break						

		default:						
			break					
	endswitch
END

Function getmode(number)
	Variable number
	switch(number)	
		case 0:		
			return 19
			break						
		case 1:		
			return 19
			break						
		case 2:		
			return 19
			break						
		case 3:		
			return 8
			break						
		case 4:		
			return 6
			break						

		default:						
			break					
	endswitch
END


Function DisplayWavesbyInt(speed)
	String speed
	variable i
	for (i=0;i<3;i+=1)
		Variable diameter = getdiameter(i)
		String prefix =RetrievePrifix(Speed, diameter)
		print prefix
		String AVG=Prefix+"AVG"
		String AVGsd=Prefix+"AVGsd"
		String AVGpnts=Prefix+"AVGpnts"
		String cAVG=Prefix+"cAVG"
		String cAVGpnts=Prefix+"cAVGpnts"
//		wave AVGwave=$AVG
//		wave AVGsdwave=$AVGsd
//		wave AVGpntswave=$AVGpnts
//		wave cAVGwave=$cAVG
//		wave cAVGpntswave=$cAVGpnts

		Variable j
		String number
		for (j=0;j<5;j+=1)
			number=getnumber(j)
			wave/z AVGnum=$(ReturnName(AVG,number))
			print ReturnName(AVG,number)
			wave/z AVGsdnum=$(ReturnName(AVGsd,number))
			wave/z AVGpntsnum=$(ReturnName(AVGpnts,number))
			wave/z cAVGnum=$(ReturnName(cAVG,number))
			wave/z cAVGpntsnum=$(ReturnName(cAVGpnts,number))	
			Variable CurrentMode=getmode(j)
			Variable CC=getcolor(j)
			if (i==0 && j ==0)
				Display  $ReturnName(AVG,number) vs LayersPerFrame
				ModifyGraph tick=2,mirror=2
				TextBox/C/N=text0 "\\Z08V=0.1pix/frame\rDifferent dot size (marker size reflects ø) \rDotted line = noise removed"
			else
				AppendToGraph $(ReturnName(AVG,number)) vs LayersPerFrame
			endif
			ModifyGraph mode($(ReturnName(AVG,number)))=4, marker($(ReturnName(AVG,number)))=CurrentMode,rgb($(ReturnName(AVG,number)))=(cc,cc,cc)
			AppendToGraph $(ReturnName(cAVG,number))  vs LayersPerFrame
			ModifyGraph mode($(ReturnName(cAVG,number)))=4, marker($(ReturnName(cAVG,number)))=CurrentMode,rgb($(ReturnName(cAVG,number)))=(cc,cc,cc)
			ModifyGraph lstyle($(ReturnName(cAVG,number)))=1	
			
			String NoiselessPointRatio=ReturnName((Prefix+"Noiseless"),number)
			Make/O/N=11 $NoiselessPointRatio
			wave NoiselessPRwave=$NoiselessPointRatio
			NoiselessPRwave=cAVGpntsnum/AVGpntsnum
			AppendToGraph/R $NoiselessPointRatio  vs LayersPerFrame
			ModifyGraph mode($NoiselessPointRatio)=3,marker($NoiselessPointRatio)=8
			ModifyGraph tick=2
			Label left "Measured Velocity [pix/frame]";DelayUpdate
			Label bottom "frames / vector field"
			Label right "Ratio [NoiseRemoved Vectors / All Vectors]"
			SetAxis left 0,1.8 
			ModifyGraph minor(left)=1		
		endfor
	endfor
END
//**********************************************
Function CalculateNoiselessPointRatio(speed)		// 020409 module to calculate the ratio of vectors remaining after removing noise derived vectors
	String Speed
	variable i
	for (i=0;i<3;i+=1)
		Variable diameter = getdiameter(i)
		String prefix =RetrievePrifix(Speed, diameter)
		String AVGpnts=Prefix+"AVGpnts"
		String cAVGpnts=Prefix+"cAVGpnts"
		Variable j
		String number
		for (j=0;j<5;j+=1)
			number=getnumber(j)
			wave/z AVGpntsnum=$(ReturnName(AVGpnts,number))
			wave/z cAVGpntsnum=$(ReturnName(cAVGpnts,number))
			String NoiselessPointRatio=ReturnName((Prefix+"Noiseless"),number)
			Make/O/N=11 $NoiselessPointRatio
			wave NoiselessPRwave=$NoiselessPointRatio
			NoiselessPRwave=cAVGpntsnum/AVGpntsnum
		endfor
	endfor
END

//***********************************************
Macro CalcNoiselessPntRatioMacro(speed)
	String speed
	CalculateNoiselessPointRatio(speed)
END

Macro DoSisplay(speed)
	string speed
	DisplayWavesbyInt(speed)
END