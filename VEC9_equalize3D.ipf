#pragma rtGlobals=1		// Use modern global access method.

Function/S V9_equalize3Dsimple(src3Dwave)
	wave src3Dwave
	variable z_frames=dimsize(src3Dwave,2)
	if (z_frames==0)
		Abort "Not a 3D wave: at V9_equalize3D(src3Dwave)"
	endif
	Make/O/N=(dimsize(src3Dwave,0),dimsize(src3Dwave,1)) temp2D
	Redimension/B/U temp2D
	Make/O/N=(z_frames) tempPixInt
	String NewWaveName=NameofWave(src3Dwave)+"_eq"
	Duplicate/O src3Dwave $NewWaveName
	wave dest3Dwave=$NewWaveName 
	variable i
	for (i=0; i<z_frames; i+=1)
		temp2D[][]=src3Dwave[p][q][i]
		tempPixInt[i]=V9_average2D(temp2D)
	endfor
	wavestats/Q tempPixInt
	variable AVG_max=V_max
	variable AVG_min=V_min
	printf "Max %d location %d\r",V_max,V_maxloc
	printf "Min %d location %d\r",V_min,V_minloc
	tempPixint[]=tempPixInt[p]/V_max//min
	dest3Dwave[][][]=round(src3Dwave[p][q][r]/tempPixint[r])
	Killwaves temp2D//,tempPixInt
	Display tempPixInt
	return NewWaveName
end
		
Function V9_average2D(src2Dwave)
	wave src2Dwave
	wavestats/q src2Dwave
	return V_avg
end



Function V9_do3Dequalize()
	setdatafolder root:
	String	matrix3Dname
	prompt	matrix3Dname, "which matrix?", popup  WaveList("Mat*",";","")
	Doprompt "3Dwave",matrix3Dname
	wave matrix3D=$matrix3Dname
	V9_equalize3Dsimple(matrix3D)
END

------------------------------------------
Function V9_calcBleachRate(src3Dwave,Rstart,Rend)			//031203 for getting the bleach rate
	wave src3Dwave
	variable Rstart,Rend
	variable z_frames=dimsize(src3Dwave,2)
	if (z_frames==0)
		Abort "Not a 3D wave: at V9_calcBleachRate(src3Dwave)"
	endif
	Make/O/N=(dimsize(src3Dwave,0),dimsize(src3Dwave,1)) temp2D
	Redimension/B/U temp2D
	String BlchWaveName=NameofWave(src3Dwave)+"_Blch"
	//String BlchDWaveName=NameofWave(src3Dwave)+"_BlchD"	// difference
	Make/O/N=(z_frames) $BlchWaveName
	//Make/O/N=(z_frames-1) $BlchDWaveName	
	wave BlchWave=$BlchWaveName
	//wave BlchDWave=$BlchDWaveName
	
	variable i
	for (i=0; i<z_frames; i+=1)
		temp2D[][]=src3Dwave[p][q][i]
		BlchWave[i]=V9_average2D(temp2D)
	endfor
	//BlchDWave[]=BlchWave[p+1]-BlchWave[p]
	Killwaves temp2D
	Display BlchWave
//	print BlchWaveName
	CurveFit/Q line BlchWave[Rstart,Rend] /D
	wave W_coef
	return (W_coef[1])
end

Function V9_CalcBleachRateCore(BlchWave,Rstart,Rend)		//040122
	wave BlchWave
	Variable Rstart,Rend
	CurveFit/Q line BlchWave[Rstart,Rend] /D
	wave W_coef
	return (W_coef[1])
END