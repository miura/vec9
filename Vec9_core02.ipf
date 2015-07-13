#pragma rtGlobals=1		// Use modern global access method.

//031203 LSM functions. with bleaching, without bleaching. ---> if bleaching is 0, the function can be only one. 

//the following function is unaltered from the original Least square method.	//031202
// Spatial-Temporal local optimization added
Function Vec_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber)
	variable rownumber,columnnumber,truncation,WorkingLayerNumber
	wave/z derX_subave,derY_subave,derT_subave
	NVAR bleachrate
	NVAR button_bleachcorrect	
	NVAR OptimizationMethod
	
	Make/O/N=(rownumber-truncation,columnnumber-truncation) VX,VY		//overwrite 041129
	VX=0
	VY=0
	
	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) XX,XT,YT,XY,YY
	Make/N=(rownumber-truncation,columnnumber-truncation) XXsum,XTsum,YTsum,XYsum,YYsum
	
	XX=	derX_subave*derX_subave	
	XT=	derX_subave*derT_subave
	YT=	derY_subave*derT_subave
	XY=	derX_subave*derY_subave
	YY=derY_subave*derY_subave

	if (button_bleachcorrect!=0)// && button_bleachcorrect!=3))
		Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) bX,bY
		Make/N=(rownumber-truncation,columnnumber-truncation) bXsum,bYsum
		if (button_bleachcorrect==1)
			bX=derX_subave*bleachrate
			bY=derY_subave*bleachrate
		else
			wave/z blchwave=$(V9_Original3Dwave()+"_Blch")		//040122
			NVAR Layerstart,LayerEnd	
			bX[][][]=derX_subave[p][q][r]*(BlchWave[Layerstart+r+truncation]-BlchWave[Layerstart+r])/2	//040122
			bY[][][]=derY_subave[p][q][r]*(BlchWave[Layerstart+r+truncation]-BlchWave[Layerstart+r])/2//blchwave[Layerstart+r]
		endif
	endif
		
	Killwaves derX_subave,derY_subave,derT_subave
	variable i,j,k
	variable x_start,x_end,y_start,y_end
	if (OptimizationMethod!=1)		//041129 1: TLO 2:STLO 3x3 3: STLO 5x5
		x_start=0-(OptimizationMethod-1)
		x_end=(OptimizationMethod-1)+1
		y_start=0-(OptimizationMethod-1)
		y_end=(OptimizationMethod-1)+1
		 print "STL optimization"  
	else
		x_start=0
		x_end=1
		y_start=0
		y_end=1
		 print "TL optimization"  
	endif		
	
	for (i=x_start; i<x_end;i+=1)	
		for (j=-y_start; j<y_end;j+=1)
			for (k=0;k<WorkingLayerNumber-truncation; k+=1)
//	do
//		if (n>=(WorkingLayerNumber-truncation))
//			break
//		endif
//		XXsum[][]+=XX[p][q][k]
//		XTsum[][]+=XT[p][q][k]
//		YTsum[][]+=YT[p][q][k]
//		XYsum[][]+=XY[p][q][k]
//		YYsum[][]+=YY[p][q][k]
//		n=n+1				
//	while (n<(WorkingLayerNumber-truncation))
				XXsum[][]+=XX[p+i][q+j][k]
				XTsum[][]+=XT[p+i][q+j][k]
				YTsum[][]+=YT[p+i][q+j][k]
				XYsum[][]+=XY[p+i][q+j][k]
				YYsum[][]+=YY[p+i][q+j][k]
				if (button_bleachcorrect!=0)
					bXsum[][]+=bX[p+i][q+j][k]
					bYsum[][]+=bY[p+i][q+j][k]	
				endif				
			endfor
		endfor
	endfor
        KillWaves XX,XT,YT,XY,YY
        
	if (button_bleachcorrect!=0)
		VX= -1*(YYsum*(XTsum-bXsum)-XYsum*(YTsum-bYsum)) / (XXsum*YYsum-XYsum^2)
		VY= -1*(XXsum*(YTsum-bYsum)-XYsum*(XTsum-bXsum)) / (XXsum*YYsum-XYsum^2)
		KillWaves bXsum,bYsum,bx,by
	else
		VX= -1*(YYsum*XTsum-XYsum*YTsum) / (XXsum*YYsum-XYsum^2)
		VY= -1*(XXsum*YTsum-XYsum*XTsum) / (XXsum*YYsum-XYsum^2)
	       print "Bleach Correction OFF"  
	endif

       KillWaves XXsum,XTsum,YTsum,XYsum,YYsum

END




// commentarized 041129
////041126		STLO optimaization: generate error function from surrouding pixels in XY plane and time.
////			edge treatment is not done yet.
//Function Vec_STLO_LSM(rownumber,columnnumber,truncation,WorkingLayerNumber)
//	variable rownumber,columnnumber,truncation,WorkingLayerNumber
//	wave/z derX_subave,derY_subave,derT_subave	
//	Make/N=(rownumber-truncation,columnnumber-truncation) VX,VY
//	VX=0
//	VY=0
//	
//	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) XX,XT,YT,XY,YY
//	Make/N=(rownumber-truncation,columnnumber-truncation) XXsum,XTsum,YTsum,XYsum,YYsum
//	
//	XX=	derX_subave*derX_subave	
//	XT=	derX_subave*derT_subave
//	YT=	derY_subave*derT_subave
//	XY=	derX_subave*derY_subave
//	YY=	derY_subave*derY_subave
//	
//	Killwaves derX_subave,derY_subave,derT_subave
//	
//	variable i,j,k
////	variable k=0
//
//	for (i=-1; i<2;i+=1)	
//		for (j=-1; j<2;j+=1)
//			for (k=0; k<(WorkingLayerNumber-truncation); k+=1)
////		if (n>=(WorkingLayerNumber-truncation))
////			break
////		endif
//				XXsum[][]+=XX[p+i][q+j][k]
//				XTsum[][]+=XT[p+i][q+j][k]
//				YTsum[][]+=YT[p+i][q+j][k]
//				XYsum[][]+=XY[p+i][q+j][k]
//				YYsum[][]+=YY[p+i][q+j][k]
//				
////		n=n+1				
////	while (n<(WorkingLayerNumber-truncation))
//			endfor 
//		endfor
//	endfor
//       KillWaves XX,XT,YT,XY,YY
//        
//	VX= -1*(YYsum*XTsum-XYsum*YTsum) / (XXsum*YYsum-XYsum^2)
//	VY= -1*(XXsum*YTsum-XYsum*XTsum) / (XXsum*YYsum-XYsum^2)
//	
//       KillWaves XXsum,XTsum,YTsum,XYsum,YYsum
//       print "Bleach Correction OFF"       
//END
//
////the following function is added with the bleaching	//031202
//Function Vec_LSM_bleach(rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate)
//	variable rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate
//	wave/z derX_subave,derY_subave,derT_subave	
//	Make/N=(rownumber-truncation,columnnumber-truncation) VX,VY
//	VX=0
//	VY=0
//	
//	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) XX,XT,YT,XY,YY,bX,bY
//	Make/N=(rownumber-truncation,columnnumber-truncation) XXsum,XTsum,YTsum,XYsum,YYsum,bXsum,bYsum
//	
//	XX=	derX_subave*derX_subave	
//	XT=	derX_subave*derT_subave
//	YT=	derY_subave*derT_subave
//	XY=	derX_subave*derY_subave
//	YY=	derY_subave*derY_subave
//	
//	bX=derX_subave*bleachrate
//	bY=derY_subave*bleachrate
//	
//	Killwaves derX_subave,derY_subave,derT_subave
//	
//	variable n=0
//	do
//		if (n>=(WorkingLayerNumber-truncation))
//			break
//		endif
//		XXsum[][]+=XX[p][q][n]
//		XTsum[][]+=XT[p][q][n]
//		YTsum[][]+=YT[p][q][n]
//		XYsum[][]+=XY[p][q][n]
//		YYsum[][]+=YY[p][q][n]
//		bXsum[][]+=bX[p][q][n]
//		bYsum[][]+=bY[p][q][n]		
//		n=n+1				
//	while (n<(WorkingLayerNumber-truncation))
//        KillWaves XX,XT,YT,XY,YY,bX,bY
//        
//	VX= -1*(YYsum*(XTsum-bXsum)-XYsum*(YTsum-bYsum)) / (XXsum*YYsum-XYsum^2)
//	VY= -1*(XXsum*(YTsum-bYsum)-XYsum*(XTsum-bXsum)) / (XXsum*YYsum-XYsum^2)
//	
//       KillWaves XXsum,XTsum,YTsum,XYsum,YYsum,bXsum,bYsum
//       print "Bleach Correction ON1"
//END
//
////the following function is added with the bleaching	//031202
//// then modified to refer to the bleaching wave //040122
//Function Vec_LSM_bleachV2(rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate)
//	variable rownumber,columnnumber,truncation,WorkingLayerNumber,bleachrate
//	wave/z derX_subave,derY_subave,derT_subave	
//	wave/z blchwave=$(V9_Original3Dwave()+"_Blch")		//040122
//	Make/N=(rownumber-truncation,columnnumber-truncation) VX,VY
//	VX=0
//	VY=0
//		
//	Make/N=(rownumber-truncation,columnnumber-truncation, WorkingLayerNumber-truncation) XX,XT,YT,XY,YY,bX,bY
//	Make/N=(rownumber-truncation,columnnumber-truncation) XXsum,XTsum,YTsum,XYsum,YYsum,bXsum,bYsum
//	
//	XX=	derX_subave*derX_subave	
//	XT=	derX_subave*derT_subave
//	YT=	derY_subave*derT_subave
//	XY=	derX_subave*derY_subave
//	YY=derY_subave*derY_subave
//	
//	NVAR Layerstart,LayerEnd
//	
////	bX[][][]=derX_subave[p][q][r]*V9_CalcBleachRateCore(BlchWave,(Layerstart+r),(Layerstart+r+2))	//040122
////	bY[][][]=derY_subave[p][q][r]*V9_CalcBleachRateCore(BlchWave,(Layerstart+r),(Layerstart+r+2))//blchwave[Layerstart+r]
//	bX[][][]=derX_subave[p][q][r]*(BlchWave[Layerstart+r+truncation]-BlchWave[Layerstart+r])/2	//040122
//	bY[][][]=derY_subave[p][q][r]*(BlchWave[Layerstart+r+truncation]-BlchWave[Layerstart+r])/2//blchwave[Layerstart+r]
//	
//	Killwaves derX_subave,derY_subave,derT_subave
//	
//	variable n=0
//	do
//		if (n>=(WorkingLayerNumber-truncation))
//			break
//		endif
//		XXsum[][]+=XX[p][q][n]
//		XTsum[][]+=XT[p][q][n]
//		YTsum[][]+=YT[p][q][n]
//		XYsum[][]+=XY[p][q][n]
//		YYsum[][]+=YY[p][q][n]
//		bXsum[][]+=bX[p][q][n]
//		bYsum[][]+=bY[p][q][n]		
//		n=n+1				
//	while (n<(WorkingLayerNumber-truncation))
//        KillWaves XX,XT,YT,XY,YY,bX,bY
//        
//	VX= -1*(YYsum*(XTsum-bXsum)-XYsum*(YTsum-bYsum)) / (XXsum*YYsum-XYsum^2)
//	VY= -1*(XXsum*(YTsum-bYsum)-XYsum*(XTsum-bXsum)) / (XXsum*YYsum-XYsum^2)
//	
//       KillWaves XXsum,XTsum,YTsum,XYsum,YYsum,bXsum,bYsum
//       print "Bleach Correction ON2"
//END


