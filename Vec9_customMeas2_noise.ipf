#pragma rtGlobals=1		// Use modern global access method.

Function VelocityToPoint(velocity)
	variable velocity
	return (velocity/0.2)
END

Function PointToVelocity(Point)
	variable point
	return point*0.2
END

function V9_difIntensityALL(velocity,direction)		//030224    for s/n vs measured velocity. Fix the velocity.
	variable velocity,direction
	variable dotsize,intensity,size
	variable point=VelocityToPoint(velocity)
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string FVMstatwavename,FVSstatwavename,FGMstatwavename,FGSstatwavename
	String SNwaveSuffix,SNvelwave,SNvelFwave,SNvelSDwave,SNvelFSDwave
	String SNdirwave,SNdirFwave,SNdirSDwave,SNdirFSDwave
	string suffix
	variable i,j,k
	make/O/N=5 SN
	SN={5.1,9.6,14.2,17.2,19.4}		//noise 30
//	SN={5.1,9.6,14.2,17.2,19.4}		//noise 60
//	for (j=0;j<3;j+=1)
	
	//direction=V9_returnAngles(j)
	for (k=0;k<6;k+=1)		//dot size loop
		size=V9_dotsizeCorrection(k)
		SNwaveSuffix="D"+num2Str(direction)+"S"+num2str(size)+"V"+num2str(velocity)
//		SNwavePreffix="S"+num2str(size)+"V"+num2str(velocity)		
		SNvelwave=SNwaveSuffix+"vel"
		SNvelSDwave=SNwaveSuffix+"velSD"
		SNvelFwave=SNwaveSuffix+"velF"
		SNvelFSDwave=SNwaveSuffix+"velFSD"
		SNdirwave=SNwaveSuffix+"dir"
		SNdirSDwave=SNwaveSuffix+"dirSD"
		SNdirFwave=SNwaveSuffix+"dirF"
		SNdirFSDwave=SNwaveSuffix+"dirFSD"
		
		
		Make/o/n=6 $SNvelwave,$SNvelFwave,$SNvelSDwave,$SNvelFSDwave
		Make/o/n=6 $SNdirwave,$SNdirFwave,$SNdirSDwave,$SNdirFSDwave	
		wave/z SNvel=$SNvelwave,SNvelF=$SNvelFwave,SNvelSD=$SNvelSDwave,SNvelFSD=$SNvelFSDwave
		wave/z SNdir=$SNdirwave,SNdirF=$SNdirFwave,SNdirSD=$SNdirSDwave,SNdirFSD=$SNdirFSDwave

		string windowsuffix="D"+num2Str(direction)+"V"+num2str(velocity)
		string win_vel=windowsuffix+"_SNvsSpeed"
		String win_dir=windowsuffix+"_SNvsDirection"
	
		for (i=1;i<6;i+=1)				//intensity loop
				intensity=V9_returnIntensities(i)
				suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)
//				VMstatwavename="VelMean"+suffix
//				VSstatwavename="VelSd"+suffix
//				GMstatwavename="GraMean"+suffix
//				GSstatwavename="GraSd"+suffix
				VMstatwavename="VelavMean"+suffix		//030226
				VSstatwavename="VelavSd"+suffix			//030226
				GMstatwavename="GraavMean"+suffix		//030226
				GSstatwavename="GraavSd"+suffix			//030226
						
				FVMstatwavename="F"+VMstatwavename		// 030224 for noise added
				FVSstatwavename="F"+VSstatwavename		// 030224 for noise added
				FGMstatwavename="F"+GMstatwavename		// 030224 for noise added
				FGSstatwavename="F"+GSstatwavename		// 030224 for noise added
				
				wave/z VMstatwave=$VMstatwavename,FVMstatwave=$FVMstatwavename
				wave/z VSstatwave=$VSstatwavename,FVSstatwave=$FVSstatwavename
				wave/z GMstatwave=$GMstatwavename,FGMstatwave=$FGMstatwavename
				wave/z GSstatwave=$GSstatwavename,FGSstatwave=$FGSstatwavename				
				SNvel[i]=VMstatwave[point]
				SNvelSD[i]=VSstatwave[point]
				SNvelF[i]=FVMstatwave[point]
				SNvelFSD[i]=FVSstatwave[point]
				
				SNdir[i]=GMstatwave[point]
				SNdirSD[i]=GSstatwave[point]
				SNdirF[i]=FGMstatwave[point]
				SNdirFSD[i]=FGSstatwave[point]
				
		endfor					
//		//speed graph
		dowindow/F $(win_vel)	
		if (V_flag==0)
				display $SNvelwave vs SN
				dowindow/c $win_vel
				ErrorBars $SNvelwave Y,wave=($SNvelSDwave,$SNvelSDwave)
				AppendToGraph/w=$(win_vel) $SNvelFwave vs SN
				ErrorBars $SNvelFwave Y,wave=($SNvelFSDwave,$SNvelFSDwave)
				//ModifyGraph height={Plan,1,left,bottom}
				//ModifyGraph grid=1,nticks(bottom)=10	
				Label left "Measured Speed [pix/frame]"
				Label bottom "S/N "			
				TextBox/C/N=text1/A=MC ("\\Z07Direction"+num2str(direction+270)+"\rVelocity "+num2Str(velocity))
				TextBox/C/N=text1/A=RC/X=0/Y=0
				//Legend/C/N=text0/J ("\\Z08\\s("+SNvelwave+") Original\r\\s("+SNvelFwave+") Filtered")
				ModifyGraph rgb($SNvelwave)=(0,0,52224),lstyle($SNvelwave)=1
				ModifyGraph width=200
				ModifyGraph height={Aspect,1}	
				dowindow/F $(win_vel)	
		else
				dowindow/F $(win_vel)		
				AppendToGraph/w=$(win_vel) $SNvelwave vs SN
				ErrorBars $SNvelwave Y,wave=($SNvelSDwave,$SNvelSDwave)				
				AppendToGraph/w=$(win_vel) $SNvelFwave vs SN
				ErrorBars $SNvelFwave Y,wave=($SNvelFSDwave,$SNvelFSDwave)				
				ModifyGraph rgb($SNvelwave)=(0,0,52224),lstyle($SNvelwave)=1;			

		endif	
		Tag/w=$win_vel/N=$("Size"+num2str(size)) $SNvelFwave,(2),("\\Z07Size"+num2Str(size))
			
		//angle graph
		dowindow/F $(win_dir)	
		if (V_flag==0)		
				display $SNdirwave vs SN
				dowindow/c $win_dir
				ErrorBars $SNdirwave Y,wave=($SNdirSDwave,$SNdirSDwave)					
				AppendToGraph/w=$(win_dir) $SNdirFwave vs SN
				ErrorBars $SNdirFwave Y,wave=($SNdirFSDwave,$SNdirFSDwave)					
				//ModifyGraph height={Plan,1,left,bottom}
				//ModifyGraph grid=1,nticks(bottom)=10	
				Label left "Measured Angle [degrees]"
				Label bottom "S/N "			
				TextBox/C/N=text1/A=MC ("\\Z07Direction"+num2str(direction+270)+"\rVelocity "+num2Str(velocity))
				TextBox/C/N=text1/A=RC/X=0/Y=0
				//Legend/C/N=text0/J ("\\Z08\\s("+SNdirwave+") Original\r\\s("+SNdirFwave+") Filtered")				
				ModifyGraph rgb($SNdirwave)=(0,0,52224),lstyle($SNdirwave)=1
				ModifyGraph width=200			
				ModifyGraph height={Aspect,1}
				dowindow/F $(win_dir)	
		else
				dowindow/F $(win_dir)		
				AppendToGraph/w=$(win_dir) $SNdirwave vs SN
				ErrorBars $SNdirwave Y,wave=($SNdirSDwave,$SNdirSDwave)						
				AppendToGraph/w=$(win_dir) $SNdirFwave vs SN
				ErrorBars $SNdirFwave Y,wave=($SNdirFSDwave,$SNdirFSDwave)						
				ModifyGraph rgb($SNdirwave)=(0,0,52224),lstyle($SNdirwave)=1;			
		endif	
//			Tag/N=$("textD"+num2str(direction)+num2str(i+2)) $GMstatwavename, (1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))
		Tag/w=$win_dir/N=$("Size"+num2str(size)) $SNdirFwave,(2),("\\Z07Size"+num2Str(size))
		
	endfor
	dowindow/F $(win_vel)	
	Legend/C/N=text0/J ("\\Z08\\s("+SNvelwave+") Original\r\\s("+SNvelFwave+") Filtered")	
	dowindow/F $(win_dir)	
	Legend/C/N=text0/J ("\\Z08\\s("+SNdirwave+") Original\r\\s("+SNdirFwave+") Filtered")			
	NewLayout/C=1 
	AppendLayoutObject/F=0 graph $(win_vel)
	AppendLayoutObject/F=0 graph $(win_dir)
	TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
	ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
//	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Direction: "+num2str(direction+270)+"\rVelocity: "+num2str(velocity)	
	ModifyLayout units=0;
	ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60
	ModifyLayout left($(win_vel))=99.75
	ModifyLayout top($(win_vel))=170.25
	ModifyLayout left($(win_dir))=99.75
	ModifyLayout top($(win_dir))=450
END


function V9_differentIntensityALL_avVec(dotsize)		//030226 modified V9_differentIntensityALL to show averaged vectors
	variable dotsize
	variable direction,intensity,size
	variable velloop
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	variable i,j
	for (j=0;j<3;j+=1)
	direction= V9_returnAngles(j)
	for (i=0;i<6;i+=1)
		//i=size	
		intensity=V9_returnIntensities(i)
		size=V9_dotsizeCorrection(dotsize)
//		string windowsuffix="I"+num2str(V9_returnIntensities(i))+"D"+num2Str(direction)+"S"+num2Str(V9_dotsizeCorrection(i))
//		string windowsuffix="D"+num2Str(direction)+"S"+num2Str(size)
		string windowsuffix="S"+num2Str(size)
		string win_vel=windowsuffix+"_velocity"
		string win_dir=windowsuffix+"_direction"

		string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)
		VMstatwavename="VelavMean"+suffix		//030226
		VSstatwavename="VelavSd"+suffix			//030226
		GMstatwavename="GraavMean"+suffix		//030226
		GSstatwavename="GraavSd"+suffix			//030226

		VMstatwavename="F"+VMstatwavename		// 030224 for noise added
		VSstatwavename="F"+VSstatwavename		// 030224 for noise added
		GMstatwavename="F"+GMstatwavename		// 030224 for noise added
		GSstatwavename="F"+GSstatwavename		// 030224 for noise added
				
		//speed graph
		if (i==0&&j==0)
			display $VMstatwavename
			ModifyGraph height={Plan,1,left,bottom}
			ModifyGraph grid=1,nticks(bottom)=10	
			Label left "Measured Speed [pix/frame]"
			Label bottom "speed [pix/frame]"			
			dowindow/c $win_vel
			TextBox/C/N=text1/A=MC ("\\Z07Dotsize "+num2Str(size))
			TextBox/C/N=text1/A=RC/X=0/Y=0			
			dowindow/F $(win_vel)	
		else
			dowindow/F $(win_vel)		
			AppendToGraph/w=$(win_vel) $VMstatwavename
		endif	
		Tag/w=$win_vel/N=$("textD"+num2str(direction)+num2str(i+2)) $VMstatwavename,(1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))

		//angle graph
		if (i==0&&j==0)
			display $GMstatwavename
			//AppendTograph/L=originalAxis/B=speedAxis  $GMstatwavename
			Label left "Direction [degrees]"
			Label bottom "speed [pix/frame]"
			ModifyGraph grid(bottom)=1,tick(bottom)=2
			ModifyGraph nticks(bottom)=15
			dowindow/c $(windowsuffix+"_direction")
			TextBox/C/N=text1/A=MC ("\\Z07Dotsize "+num2Str(size))
			TextBox/C/N=text1/A=RC/X=0/Y=0
		else
			dowindow/F $(windowsuffix+"_direction")
			AppendToGraph/w=$(windowsuffix+"_direction") $GMstatwavename
		endif
		Tag/N=$("textD"+num2str(direction)+num2str(i+2)) $GMstatwavename, (1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))
	endfor
	endfor
	NewLayout/C=1 
	AppendLayoutObject/F=0 graph $(windowsuffix+"_direction")
	AppendLayoutObject/F=0 graph $(windowsuffix+"_velocity")
	TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
	ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
//	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Averaged Vecs\rDirection: "+num2str(direction+270)+"\rDot Size: "+num2str(V9_dotsizeCorrection(dotsize))	
	ModifyLayout units=0;
	ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60
	ModifyLayout left($(win_vel))=99.75
	ModifyLayout top($(win_vel))=170.25
	ModifyLayout left($(win_dir))=99.75
	ModifyLayout top($(win_dir))=450
END


//030227 further modification for SN detail analysis
function V9_difSNALL(velocity,direction)		//030227   for s/n vs measured velocity. Fixed velocity & direction.
	variable velocity,direction
	variable dotsize,intensity,size
	variable point=VelocityToPoint(velocity)
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string FVMstatwavename,FVSstatwavename,FGMstatwavename,FGSstatwavename
	String SNwaveSuffix,SNvelwave,SNvelFwave,SNvelSDwave,SNvelFSDwave
	String SNdirwave,SNdirFwave,SNdirSDwave,SNdirFSDwave
	string suffix
	variable i,j,k
	make/O/N=20 SN
	SN={5.1,9.6,14.2,17.2,19.4}		//noise 30
//	SN={5.1,9.6,14.2,17.2,19.4}		//noise 60
//	for (j=0;j<3;j+=1)
	
	//direction=V9_returnAngles(j)
	for (k=0;k<6;k+=1)		//dot size loop
		size=V9_dotsizeCorrection(k)
		SNwaveSuffix="D"+num2Str(direction)+"S"+num2str(size)+"V"+num2str(velocity)
//		SNwavePreffix="S"+num2str(size)+"V"+num2str(velocity)		
		SNvelwave=SNwaveSuffix+"vel"
		SNvelSDwave=SNwaveSuffix+"velSD"
		SNvelFwave=SNwaveSuffix+"velF"
		SNvelFSDwave=SNwaveSuffix+"velFSD"
		SNdirwave=SNwaveSuffix+"dir"
		SNdirSDwave=SNwaveSuffix+"dirSD"
		SNdirFwave=SNwaveSuffix+"dirF"
		SNdirFSDwave=SNwaveSuffix+"dirFSD"
		
		
		Make/o/n=6 $SNvelwave,$SNvelFwave,$SNvelSDwave,$SNvelFSDwave
		Make/o/n=6 $SNdirwave,$SNdirFwave,$SNdirSDwave,$SNdirFSDwave	
		wave/z SNvel=$SNvelwave,SNvelF=$SNvelFwave,SNvelSD=$SNvelSDwave,SNvelFSD=$SNvelFSDwave
		wave/z SNdir=$SNdirwave,SNdirF=$SNdirFwave,SNdirSD=$SNdirSDwave,SNdirFSD=$SNdirFSDwave

		string windowsuffix="D"+num2Str(direction)+"V"+num2str(velocity)
		string win_vel=windowsuffix+"_SNvsSpeed"
		String win_dir=windowsuffix+"_SNvsDirection"
		
//		for (i=1;i<6;i+=1)				//intensity loop
		intensity=115			// instead of above line, fix the intensity
		variable vel
		for (i=0;i<20;i+=20)		//030227 for noise loop
//				intensity=V9_returnIntensities(i)		// comnted out 030227 
//				suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)		// comnted out 030227
				vel=4*i 
				suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)+"V"+num2str(vel)
				VMstatwavename="VelMean"+suffix
				VSstatwavename="VelSd"+suffix
				GMstatwavename="GraMean"+suffix
				GSstatwavename="GraSd"+suffix
//				VMstatwavename="VelavMean"+suffix		//030226 for graphing averaged
//				VSstatwavename="VelavSd"+suffix			//030226
//				GMstatwavename="GraavMean"+suffix		//030226
//				GSstatwavename="GraavSd"+suffix			//030226
						
				FVMstatwavename="F"+VMstatwavename		// 030224 for noise added
				FVSstatwavename="F"+VSstatwavename		// 030224 for noise added
				FGMstatwavename="F"+GMstatwavename		// 030224 for noise added
				FGSstatwavename="F"+GSstatwavename		// 030224 for noise added
				
				wave/z VMstatwave=$VMstatwavename,FVMstatwave=$FVMstatwavename
				wave/z VSstatwave=$VSstatwavename,FVSstatwave=$FVSstatwavename
				wave/z GMstatwave=$GMstatwavename,FGMstatwave=$FGMstatwavename
				wave/z GSstatwave=$GSstatwavename,FGSstatwave=$FGSstatwavename				
				SNvel[i]=VMstatwave[point]
				SNvelSD[i]=VSstatwave[point]
				SNvelF[i]=FVMstatwave[point]
				SNvelFSD[i]=FVSstatwave[point]
				
				SNdir[i]=GMstatwave[point]
				SNdirSD[i]=GSstatwave[point]
				SNdirF[i]=FGMstatwave[point]
				SNdirFSD[i]=FGSstatwave[point]
				
		endfor					
//		//speed graph
		dowindow/F $(win_vel)	
		if (V_flag==0)
				display $SNvelwave vs SN
				dowindow/c $win_vel
				ErrorBars $SNvelwave Y,wave=($SNvelSDwave,$SNvelSDwave)
				AppendToGraph/w=$(win_vel) $SNvelFwave vs SN
				ErrorBars $SNvelFwave Y,wave=($SNvelFSDwave,$SNvelFSDwave)
				//ModifyGraph height={Plan,1,left,bottom}
				//ModifyGraph grid=1,nticks(bottom)=10	
				Label left "Measured Speed [pix/frame]"
				Label bottom "S/N "			
				TextBox/C/N=text1/A=MC ("\\Z07Direction"+num2str(direction+270)+"\rVelocity "+num2Str(velocity))
				TextBox/C/N=text1/A=RC/X=0/Y=0
				//Legend/C/N=text0/J ("\\Z08\\s("+SNvelwave+") Original\r\\s("+SNvelFwave+") Filtered")
				ModifyGraph rgb($SNvelwave)=(0,0,52224),lstyle($SNvelwave)=1
				ModifyGraph width=200
				ModifyGraph height={Aspect,1}	
				dowindow/F $(win_vel)	
		else
				dowindow/F $(win_vel)		
				AppendToGraph/w=$(win_vel) $SNvelwave vs SN
				ErrorBars $SNvelwave Y,wave=($SNvelSDwave,$SNvelSDwave)				
				AppendToGraph/w=$(win_vel) $SNvelFwave vs SN
				ErrorBars $SNvelFwave Y,wave=($SNvelFSDwave,$SNvelFSDwave)				
				ModifyGraph rgb($SNvelwave)=(0,0,52224),lstyle($SNvelwave)=1;			

		endif	
		Tag/w=$win_vel/N=$("Size"+num2str(size)) $SNvelFwave,(2),("\\Z07Size"+num2Str(size))
			
		//angle graph
		dowindow/F $(win_dir)	
		if (V_flag==0)		
				display $SNdirwave vs SN
				dowindow/c $win_dir
				ErrorBars $SNdirwave Y,wave=($SNdirSDwave,$SNdirSDwave)					
				AppendToGraph/w=$(win_dir) $SNdirFwave vs SN
				ErrorBars $SNdirFwave Y,wave=($SNdirFSDwave,$SNdirFSDwave)					
				//ModifyGraph height={Plan,1,left,bottom}
				//ModifyGraph grid=1,nticks(bottom)=10	
				Label left "Measured Angle [degrees]"
				Label bottom "S/N "			
				TextBox/C/N=text1/A=MC ("\\Z07Direction"+num2str(direction+270)+"\rVelocity "+num2Str(velocity))
				TextBox/C/N=text1/A=RC/X=0/Y=0
				//Legend/C/N=text0/J ("\\Z08\\s("+SNdirwave+") Original\r\\s("+SNdirFwave+") Filtered")				
				ModifyGraph rgb($SNdirwave)=(0,0,52224),lstyle($SNdirwave)=1
				ModifyGraph width=200			
				ModifyGraph height={Aspect,1}
				dowindow/F $(win_dir)	
		else
				dowindow/F $(win_dir)		
				AppendToGraph/w=$(win_dir) $SNdirwave vs SN
				ErrorBars $SNdirwave Y,wave=($SNdirSDwave,$SNdirSDwave)						
				AppendToGraph/w=$(win_dir) $SNdirFwave vs SN
				ErrorBars $SNdirFwave Y,wave=($SNdirFSDwave,$SNdirFSDwave)						
				ModifyGraph rgb($SNdirwave)=(0,0,52224),lstyle($SNdirwave)=1;			
		endif	
//			Tag/N=$("textD"+num2str(direction)+num2str(i+2)) $GMstatwavename, (1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))
		Tag/w=$win_dir/N=$("Size"+num2str(size)) $SNdirFwave,(2),("\\Z07Size"+num2Str(size))
		
	endfor
	dowindow/F $(win_vel)	
	Legend/C/N=text0/J ("\\Z08\\s("+SNvelwave+") Original\r\\s("+SNvelFwave+") Filtered")	
	dowindow/F $(win_dir)	
	Legend/C/N=text0/J ("\\Z08\\s("+SNdirwave+") Original\r\\s("+SNdirFwave+") Filtered")			
	NewLayout/C=1 
	AppendLayoutObject/F=0 graph $(win_vel)
	AppendLayoutObject/F=0 graph $(win_dir)
	TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
	ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
//	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Direction: "+num2str(direction+270)+"\rVelocity: "+num2str(velocity)	
	ModifyLayout units=0;
	ModifyLayout left(text1)=80.25,top(text1)=90,width(text1)=105,height(text1)=60
	ModifyLayout left($(win_vel))=99.75
	ModifyLayout top($(win_vel))=170.25
	ModifyLayout left($(win_dir))=99.75
	ModifyLayout top($(win_dir))=450
END

Function V9_difSNALL_correct(intensity,velocity,direction)		//030227   for s/n vs measured velocity. Fixed velocity & direction.
	variable intensity,velocity,direction
	variable dotsize,size
	variable point=VelocityToPoint(velocity)
	string VMstatwavename,VSstatwavename,GMstatwavename,GSstatwavename
	string FVMstatwavename,FVSstatwavename,FGMstatwavename,FGSstatwavename
	String SNwaveSuffix,SNvelwave,SNvelFwave,SNvelSDwave,SNvelFSDwave
	String SNdirwave,SNdirFwave,SNdirSDwave,SNdirFSDwave
	string suffix
	variable i,j,k
		variable vel
		vel=10*velocity 
	//intensity=115			// instead of above line, fix the intensity

//	make/O/N=20 SN
//	SN={5.1,9.6,14.2,17.2,19.4}		//noise 30
////	SN={5.1,9.6,14.2,17.2,19.4}		//noise 60
////	for (j=0;j<3;j+=1)
	wave/z SN
	//direction=V9_returnAngles(j)
	for (k=0;k<6;k+=1)		//dot size loop
		size=V9_dotsizeCorrection(k)
		suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(size)+"V"+num2str(vel)
		VMstatwavename="VelMean"+suffix
		VSstatwavename="VelSd"+suffix
		GMstatwavename="GraMean"+suffix
		GSstatwavename="GraSd"+suffix
						
		FVMstatwavename="F"+VMstatwavename		// 030224 for noise added
		FVSstatwavename="F"+VSstatwavename		// 030224 for noise added
		FGMstatwavename="F"+GMstatwavename		// 030224 for noise added
		FGSstatwavename="F"+GSstatwavename		// 030224 for noise added
		
		wave/z VMstatwave=$VMstatwavename,FVMstatwave=$FVMstatwavename
		wave/z VSstatwave=$VSstatwavename,FVSstatwave=$FVSstatwavename
		wave/z GMstatwave=$GMstatwavename,FGMstatwave=$FGMstatwavename
		wave/z GSstatwave=$GSstatwavename,FGSstatwave=$FGSstatwavename	

		string windowsuffix="D"+num2Str(direction)+"V"+num2str(vel)
		string win_vel=windowsuffix+"_SNvsSpeed"
		String win_dir=windowsuffix+"_SNvsDirection"
							
//		//speed graph
		dowindow/F $win_vel
		if (V_flag==0)
				display $VMstatwavename vs SN
				dowindow/c $win_vel
				ErrorBars $VMstatwavename Y,wave=($VSstatwavename,$VSstatwavename)
				AppendToGraph/w=$(win_vel) $FVMstatwavename vs SN
				ErrorBars $FVMstatwavename Y,wave=($FVSstatwavename,$FVSstatwavename)
				//ModifyGraph height={Plan,1,left,bottom}
				//ModifyGraph grid=1,nticks(bottom)=10	
				Label left "Measured Speed [pix/frame]"
				Label bottom "S/N "			
				TextBox/C/N=text1/A=MC ("\\Z07Direction"+num2str(direction+270)+"\rVelocity "+num2Str(velocity))
				TextBox/C/N=text1/A=RC/X=0/Y=0
				//Legend/C/N=text0/J ("\\Z08\\s("+SNvelwave+") Original\r\\s("+SNvelFwave+") Filtered")
				ModifyGraph rgb($VMstatwavename)=(0,0,52224),lstyle($VMstatwavename)=1
				ModifyGraph width=250
				ModifyGraph height={Aspect,1}	
				ModifyGraph log(bottom)=1;SetAxis bottom 2.5,100
				ModifyGraph grid(left)=1 
				dowindow/F $(win_vel)	
		else
				dowindow/F $win_vel		
				AppendToGraph/w=$win_vel $VMstatwavename vs SN
				ErrorBars $VMstatwavename Y,wave=($VSstatwavename,$VSstatwavename)				
				AppendToGraph/w=$win_vel $FVMstatwavename vs SN
				ErrorBars $FVMstatwavename Y,wave=($FVSstatwavename,$FVSstatwavename)				
				ModifyGraph rgb($VMstatwavename)=(0,0,52224),lstyle($VMstatwavename)=1;			

		endif	
		Tag/w=$win_vel/N=$("Size"+num2str(size)) $FVMstatwavename,(2),("\\Z07Size"+num2Str(size))
			
		//angle graph
		dowindow/F $(win_dir)
		if (V_flag==0)		
				display $GMstatwavename vs SN
				dowindow/c $(win_dir)
				ErrorBars $GMstatwavename Y,wave=($GSstatwavename,$GSstatwavename)					
				AppendToGraph/w=$win_dir $FGMstatwavename vs SN
				ErrorBars $FGMstatwavename Y,wave=($FGSstatwavename,$FGSstatwavename)					
				//ModifyGraph height={Plan,1,left,bottom}
				//ModifyGraph grid=1,nticks(bottom)=10	
				Label left "Measured Angle [degrees]"
				Label bottom "S/N "			
				TextBox/C/N=text1/A=MC ("\\Z07Direction"+num2str(direction+270)+"\rVelocity "+num2Str(velocity))
				TextBox/C/N=text1/A=RC/X=0/Y=0
				//Legend/C/N=text0/J ("\\Z08\\s("+SNdirwave+") Original\r\\s("+SNdirFwave+") Filtered")				
				ModifyGraph rgb($GMstatwavename)=(0,0,52224),lstyle($GMstatwavename)=1
				ModifyGraph width=250			
				ModifyGraph height={Aspect,1}
				ModifyGraph log(bottom)=1;SetAxis bottom 2.5,100 
				ModifyGraph grid(left)=1
				dowindow/F $win_dir	
		else
				dowindow/F $win_dir		
				AppendToGraph/w=$win_dir $GMstatwavename vs SN
				ErrorBars $GMstatwavename Y,wave=($GSstatwavename,$GSstatwavename)						
				AppendToGraph/w=$win_dir $FGMstatwavename vs SN
				ErrorBars $FGMstatwavename Y,wave=($FGSstatwavename,$FGSstatwavename)						
				ModifyGraph rgb($GMstatwavename)=(0,0,52224),lstyle($GMstatwavename)=1;			
		endif	
//			Tag/N=$("textD"+num2str(direction)+num2str(i+2)) $GMstatwavename, (1+i*1.8),("\\Z07Int"+num2Str(intensity)+"D"+num2str(direction))
		Tag/w=$win_dir/N=$("Size"+num2str(size)) $FGMstatwavename,(2),("\\Z07Size"+num2Str(size))
		
	endfor
	dowindow/F $(win_vel)	
	Legend/C/N=text0/J ("\\Z08\\s("+VMstatwavename+") Original\r\\s("+FVMstatwavename+") Filtered")	
	dowindow/F $(win_dir)	
	Legend/C/N=text0/J ("\\Z08\\s("+GMstatwavename+") Original\r\\s("+FGMstatwavename+") Filtered")			
	NewLayout/C=1 
	AppendLayoutObject/F=0 graph $(win_vel)
	AppendLayoutObject/F=0 graph $(win_dir)
	TextBox/C/N=text0/A=LB/X=4.15/Y=97.21 "Kota Miura\r"+date()
	ModifyLayout left(text0)=300,top(text0)=699.75,width(text0)=99.75,height(text0)=39.75
//	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Intensity: "+num2str(intensity)+"\rDirection: "+num2str(direction)//+"\rDot Size: "+num2str(V9_dotsizeCorrection(i))	
	TextBox/C/N=text1/A=LB/X=4.15/Y=97.21 "\\Z16Direction: "+num2str(direction+270)+"\rVelocity: "+num2str(velocity)	
	ModifyLayout units=0;
	ModifyLayout left(text1)=78.75,top(text1)=81.75,width(text1)=105,height(text1)=60
	ModifyLayout left($(win_vel))=187.25
	ModifyLayout top($(win_vel))=104.25
	ModifyLayout left($(win_dir))=187.25
	ModifyLayout top($(win_dir))=447
END


///******************* noise SN vector field special

Function	initializeSNStatWaves(intensity,direction,dotsize,velocity,category_noise,filter)
	variable intensity,direction,dotsize,velocity,category_noise,filter
	string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)+"V"+num2Str(velocity)
	string VMstatwavename="VelMean"+suffix
	string VSstatwavename="VelSd"+suffix
	string GMstatwavename="GraMean"+suffix
	string GSstatwavename="GraSd"+suffix

	string VMavstatwavename="VelavMean"+suffix
	string VSavstatwavename="VelavSd"+suffix
	string GMavstatwavename="GraavMean"+suffix
	string GSavstatwavename="GraavSd"+suffix
	
	if (filter==1)
		VMstatwavename="F"+VMstatwavename
		VSstatwavename="F"+VSstatwavename
		GMstatwavename="F"+GMstatwavename
		GSstatwavename="F"+GSstatwavename
	
		VMavstatwavename="F"+VMavstatwavename
		VSavstatwavename="F"+VSavstatwavename
		GMavstatwavename="F"+GMavstatwavename
		GSavstatwavename="F"+GSavstatwavename
	endif	
	//setdatafolder root:
	Make/o/n=(category_noise) $VMstatwavename,$VSstatwavename,$GMstatwavename,$GSstatwavename
	Make/o/n=(category_noise) $VMavstatwavename,$VSavstatwavename,$GMavstatwavename,$GSavstatwavename

	wave/z VMstat=$VMstatwavename, VSstat=$VSstatwavename,GMstat=$GMstatwavename,GSstat=$GSstatwavename
	wave/z VMavstat=$VMavstatwavename, VSavstat=$VSavstatwavename,GMavstat=$GMavstatwavename,GSavstat=$GSavstatwavename

	//Setscale/P x 0,0.2,"", VMstat,VSstat,GMstat,GSstat,VMavstat,VSavstat,GMavstat,GSavstat
END


Function V9_recordSNStats(VelLoop,intensity,direction,dotsize,velocity,filter)	//030227
	//wave VecLengthWave,GradWave
	variable velloop,intensity,direction,dotsize,velocity,filter
	string suffix="I"+num2str(intensity)+"D"+num2Str(direction)+"S"+num2Str(dotsize)+"V"+num2str(velocity)
	string VMstatwavename="VelMean"+suffix
	string VSstatwavename="VelSd"+suffix
	string GMstatwavename="GraMean"+suffix
	string GSstatwavename="GraSd"+suffix

	string VMavstatwavename="VelavMean"+suffix
	string VSavstatwavename="VelavSd"+suffix
	string GMavstatwavename="GraavMean"+suffix
	string GSavstatwavename="GraavSd"+suffix
	
	if (filter==1)
		VMstatwavename="F"+VMstatwavename
		VSstatwavename="F"+VSstatwavename
		GMstatwavename="F"+GMstatwavename
		GSstatwavename="F"+GSstatwavename
	
		VMavstatwavename="F"+VMavstatwavename
		VSavstatwavename="F"+VSavstatwavename
		GMavstatwavename="F"+GMavstatwavename
		GSavstatwavename="F"+GSavstatwavename
	endif
	
	wave/z VM=$VMstatwavename,VS=$VSstatwavename,GM=$GMstatwavename,GS=$GSstatwavename
	wave/z VMav=$VMavstatwavename,VSav=$VSavstatwavename,GMav=$GMavstatwavename,GSav=$GSavstatwavename

	if (waveexists(VM))
		if (filter==0)
			wave/z GradWave=$("deg")
			wave/z VecLengthWave=$("mag")
			wave/z GradWaveAV=$("degAV")
			wave/z VecLengthWaveAV=$("magAV")
		else		// filtered
			wave/z GradWave=$("degF")
			wave/z VecLengthWave=$("magF")
			wave/z GradWaveAV=$("degAVF")
			wave/z VecLengthWaveAV=$("magAVF")		
		endif
		if (waveexists(VecLengthWave))
			wavestats/q VecLengthWave
			if (numtype(V_avg)==0)
				VM[VelLoop]=V_avg
				VS[VelLoop]=V_sdev
			else 
				VM[VelLoop]=0
				VS[VelLoop]=0
			endif
			//wavestats/q GradWave
			CircularStatistics2D(GradWave,2)
			NVAR/z X_bar
			NVAR/z delta_deg
			if (numtype(X_bar)==0)
				GM[VelLoop]=X_bar
				GS[VelLoop]=delta_deg
			else
				GM[VelLoop]=0
				GS[VelLoop]=0
			endif
			wavestats/q VecLengthWaveAV
			if (numtype(V_avg)==0)
				VMav[VelLoop]=V_avg
				VSav[VelLoop]=V_sdev
			else
				VMav[VelLoop]=0
				VSav[VelLoop]=0
			endif
			//wavestats/q GradWaveAV
			CircularStatistics2D(GradWaveAV,2)			
			if (numtype(X_bar)==0)
				GMav[VelLoop]=X_bar
				GSav[VelLoop]=delta_deg
			else
				GMav[VelLoop]=0
				GSav[VelLoop]=0
			endif
		else
			print "no vel wave"
			abort
		endif	
	else
		abort "generation of stat waves seems to be failed"
	endif
END

Function V9_BatVFAnalFiltSN(intensity,direction,L_unit,frames,pathname,IntMin,IntMax)			//030227
	variable	intensity,direction,L_unit,frames,IntMin,IntMax
	string pathname
	string Filename,newfilename,foldername
	variable category_velocity=10//50
	variable category_dotsize=6
	variable category_noise=20
	variable noise
	
	NVAR/z G_IntMin,G_IntMax
	if (NVAR_exists(G_IntMin)==0)
		Variable/G G_IntMin=IntMin
		Variable/G G_intMax=IntMax
	else
		G_IntMin=IntMin
		G_intMax=IntMax
	endif
			
	variable i,j,k
	for (i=0; i<category_dotsize; i+=1)
//			initializeStatWaves(intensity,direction,V9_dotsizeCorrection(i))
//			initializeStatWavesFilt(intensity,direction,V9_dotsizeCorrection(i))
		for (j=0; j<category_velocity; j+=1)
			initializeSNStatWaves(intensity,direction,V9_dotsizeCorrection(i),j*4,category_noise,0)
			initializeSNStatWaves(intensity,direction,V9_dotsizeCorrection(i),j*4,category_noise,1)
			for (k=0; k<category_noise; k+=1)
				//filename=V9_GenerateFilename(intensity,direction,V9_dotsizeCorrection(i),(j*2))
				noise=round((60/category_noise)*k)	
				Filename=V9_GenerateFilenameSN(intensity,direction,V9_dotsizeCorrection(i),(j*4),noise)
				V9_LoadSpecifiedStack(pathname,Filename)
				newfilename=RenameTiffToMATNew(filename)	//030110			
				wave/z matrix3D=$newfilename
				V9_singleVecField(matrix3D,L_unit,frames)
				//wave/z VecLengthWave,GradWave
				V9_recordSNStats(k,intensity,direction,V9_dotsizeCorrection(i),(j*4),0)
				//setdatafolder root:
				FilteredVecFieldDerive()
				 V9_recordSNStats(k,intensity,direction,V9_dotsizeCorrection(i),(j*4),1)			
				killwaves matrix3D
			endfor
		endfor
		
		saveexperiment
	endfor
	
END


Function V9_batAnalysisSN(pathname,IntMin,IntMax)		// For noise analysis 030227
	string pathname
	variable IntMin,IntMax
	variable intensity,direction,L_unit,frames
	variable i
	L_unit=3
	frames=40
	intensity=115
	i=0
//	for (i=0;i<5;i+=1)
//	for (i=0;i<3;i+=1)		//030218 modification made for doing only 0, 30 and 45 degrees. Omit 70 and 90 degrees
		direction=V9_returnAngles(i)
		V9_BatVFAnalFiltSN(intensity,direction,L_unit,frames,pathname,IntMin,IntMax)
//	endfor
END

