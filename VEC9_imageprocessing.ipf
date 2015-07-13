#pragma rtGlobals=1		// Use modern global access method.

// 020901 Kota Miura
// for 2D hist plot analysis
// copied and modifidied VEC3D imageporcessing modules

Function V_Convrt8bitToBinary(maskwave)
	wave maskwave
	maskwave[][]=((maskwave[p][q]==0) ? 1 :0)
END

Function V_Convrt0ToNaN(maskwave)
	wave maskwave
	maskwave[][]=((maskwave[p][q]==0) ? NaN :(maskwave[p][q]))
END

Function V_ConvrtNaNTo0(maskwave)
	wave maskwave
	maskwave[][]=((numtype(maskwave[p][q])==2) ? 0 :(maskwave[p][q]))
END

Function V_InvertBinary(maskwave)
	wave maskwave
	maskwave[][]=((maskwave[p][q]==0) ? 1 :0)
END


Function V9_Zprojection_MAX(src3Dwave,des2Dwave,slices,frame)
	wave src3Dwave,des2Dwave		//XY dimension should be same
	variable slices,frame			//slices:=per time point; frame=:time point
	variable i,currentValue
	wavestats/Q src3Dwave
	des2Dwave=V_min				
	for (i=0; i<slices; i+=1)
		des2Dwave[][]=( (des2Dwave[p][q]<src3Dwave[p][q][frame+i]) ? (src3Dwave[p][q][frame+i]) : (des2Dwave[p][q]) )
	endfor
END

Function V9_Zprojection_MIN(src3Dwave,des2Dwave,slices,frame)
	wave src3Dwave,des2Dwave		//XY dimension should be same
	variable slices,frame			//slices:=per time point; frame=:time point
	variable i,currentValue
	wavestats/Q src3Dwave
	des2Dwave=V_max				
	for (i=0; i<slices; i+=1)
		des2Dwave[][]=( (des2Dwave[p][q]>src3Dwave[p][q][frame+i]) ? (src3Dwave[p][q][frame+i]) : (des2Dwave[p][q]) )
	endfor
END



Function/S V9_DetermineBackground(src3Dwave)
	wave src3Dwave
	//Make/O/N=(DimSize(src3Dwave,0),DimSize(src3Dwave,1)) temp2Dwave
	//temp2Dwave=src3Dwave[p][q][0]
	variable binwidth,binnumber
	//wavestats/Q temp2Dwave
	wavestats/Q src3Dwave
	binnumber=3			//if to change, here is the place!
	binwidth =((V_max-V_min)*1.1/binnumber)
	Make/O/N=(binnumber) tempHIST
	Histogram/B={V_min,binwidth,binnumber} src3Dwave,tempHist
	string DeterminationString
	if (tempHIST[0]>tempHist[binnumber-1])
		DeterminationString="LOW"
	else
		DeterminationString="HIGH"
	endif
	Printf "Background is %s",DeterminationString
	//Killwaves temp3Dwave,tempHIST
	Killwaves tempHIST
	return DeterminationString
END

Function V9_ZprojectionFirstFrame(src3Dwave,des2Dwave,LayerStart,LayerEND)
	wave src3Dwave,des2Dwave		//XY dimension should be same
	Variable LayerStart,LayerEND
	variable slices			
	slices=LayerEnd-Layerstart+1
	String Background=V9_DetermineBackground(src3Dwave)
	if (cmpstr(Background,"LOW")==0)
		V9_Zprojection_MAX(src3Dwave,des2Dwave,slices,Layerstart)
	else
		V9_Zprojection_MIN(src3Dwave,des2Dwave,slices,Layerstart)
	endif
END


Function V9_ExtractMidFrame(src3Dwave,LayerStart,LayerEND) //030516
	wave src3Dwave
	Variable LayerStart,LayerEND
	variable LayerMid			
	LayerMid=trunc((LayerEnd-Layerstart)/2)+Layerstart
	String MidSliceName=V9_MidSliceName(src3Dwave)		//datafolderIO.ipf
	variable width=dimsize(src3Dwave,0)
	variable height=dimsize(src3Dwave,1)
	Make/O/N=(width,height) $MidSliceName
	wave MidSlice=$MidSliceName
	MidSlice[][]=src3Dwave[p][q][LayerMid]
END

//	Function V9_ExtractFirstFrame(src3Dwave,LayerStart,LayerEND) //030516
//		wave src3Dwave
//		Variable LayerStart,LayerEND
//		variable LayerMid			
//		LayerMid=trunc((LayerEnd-Layerstart)/2)+Layerstart
//		String MidSliceName=V9_MidSliceName(src3Dwave)		//datafolderIO.ipf
//		variable width=dimsize(src3Dwave,0)
//		variable height=dimsize(src3Dwave,1)
//		Make/O/N=(width,height) $MidSliceName
//		wave MidSlice=$MidSliceName
//		MidSlice[][]=src3Dwave[p][q][LayerMid]
//	END


//030725 organize some of the things as a function

//030725
//works within the current folder
Function/s V9_Check4firstFrame(matrix3D)
	wave matrix3D
	SVAR wavename_pref
	NVAR LayerStart,LayerEnd	
	String firstframename=wavename_pref+num2str(LayerStart)+"_"+num2str(LayerEnd)+"mx"	
	if (!waveexists($firstframename))
		Make/O/N=(DimSize(matrix3D, 0),DimSize(matrix3D, 1)) $firstframename
		//Variable slices=LayerEnd-Layerstart+1
		Wave/z firstframe=$firstframename	
		V9_ZprojectionFirstFrame(matrix3D,firstframe,LayerStart,LayerEnd)
//	else
//		Wave/z firstframe=$firstframename	
	endif	
	return firstframename	
END


//***** for getting tProjection image

Function/S V9_Tproject_image(src3Dwave,proj_param)
	wave src3Dwave
	variable proj_param		//0=averaging, 1=maximum, 2=minimum
	NVAR LayerStart,LayerEnd
	Variable imageX=Dimsize(src3Dwave,0)
	Variable imageY=Dimsize(src3Dwave,1)
	Variable imageZ=Dimsize(src3Dwave,2)
	string ZPimagename=V9_ZPimageName(src3Dwave)//  030516 Nameofwave(src3Dwave)+"_zPro"
	Make/O/N=(imageX,imageY) $ZPimagename
	wave ZPimage=$ZPimagename
	Variable LayerNum=LayerEnd-LayerStart+1
//	print proj_param
//	print nameofwave(src3Dwave)
//	print nameofwave(ZPimage)

	switch(proj_param)	
		case 0:		
			V9_ImageTAverageCore(src3Dwave,ZPimage,LayerStart,LayerNum)
			break						
		case 1:		
			//V9_ImageTMaxCore(src3Dwave,ZPimage,LayerStart,LayerNum)	//replaced 030120 -- this module is somehow redundunt and not working
			V9_Zprojection_MAX(src3Dwave,ZPimage,LayerNum,LayerStart)
			break
		case 2:		
			//V9_ImageTMinCore(src3Dwave,ZPimage,LayerStart,LayerNum)	//replaced 030120
			V9_Zprojection_MIN(src3Dwave,des2Dwave,LayerNum,LayerStart)
			break
		default:		
			V9_ImageTAverageCore(src3Dwave,ZPimage,LayerStart,LayerNum)
	endswitch

	return ZPimagename
END

Function V9_ImageTAverageCore(src3Dwave,dest2Dwave,LayerStart,LayerNum)
	wave src3Dwave,dest2Dwave
	Variable LayerStart,LayerNum
	variable i
	for (i=LayerStart; i<LayerStart+LayerNum;i+=1)
		dest2Dwave[][]+=src3Dwave[p][q][i]
		dest2Dwave[][]=src3Dwave[p][q]/layerNum
	endfor
END

Function V9_ImageTMaxCore(src3Dwave,dest2Dwave,LayerStart,LayerNum)
	wave src3Dwave,dest2Dwave
	Variable LayerStart,LayerNum
	wavestats/Q src3Dwave
	dest2Dwave=V_min
	variable i
	for (i=LayerStart; i<LayerStart+LayerNum;i+=1)
		if (dest2Dwave[p][q] <src3Dwave[p][q][i])			
			dest2Dwave[p][q]=src3Dwave[p][q][i]
		endif
	endfor
END

Function V9_ImageTMinCore(src3Dwave,dest2Dwave,LayerStart,LayerNum)
	wave src3Dwave,dest2Dwave
	Variable LayerStart,LayerNum
	wavestats/Q src3Dwave
	dest2Dwave=V_max
			//print GetWavesDatafolder(src3Dwave,2)
			//print GetWavesDatafolder(dest2Dwave,2)
			//print LayerStart
			//print LayerNum
			DoUpdate	
	variable i
	for (i=LayerStart; i<LayerStart+LayerNum;i+=1)
		//if (dest2Dwave[p][q]>src3Dwave[p][q][i])
			dest2Dwave[][]= ((dest2Dwave[p][q]>src3Dwave[p][q][i]) ? src3Dwave[p][q][i] : dest2Dwave[p][q])
		//endif
	endfor
END

// 030812
// creating filter that will detect signals that has a size larger than single pixel

Function V_isSinglePixel(pixvalue,range,surroundwave)
	variable pixvalue,range
	wave surroundwave
	variable upperlimit=(1+range)*pixvalue
	variable lowerlimit=(1-range)*pixvalue	
	variable i
	variable isSingle=1
	for (i=0;i<numpnts(surroundwave);i+=1)
		if ((lowerlimit<surroundwave[i]) && (surroundwave[i]<upperlimit))
			isSingle=0
			break
		endif
	endfor
	return isSingle
END

Function V_filterCheckSurround2D(igwave,xpos,ypos,range,width,height)
	wave igwave
	variable xpos,ypos,range,width,height
	range/=100
//	variable	upperlimit=igwave[xpos][ypos]+range//(1+range)*igwave[xpos][ypos]
//	variable	lowerlimit=igwave[xpos][ypos]-range//(1-range)*igwave[xpos][ypos]	
	variable	upperlimit=igwave[xpos][ypos]*(1+range)//*igwave[xpos][ypos]		//040511
	variable	lowerlimit=igwave[xpos][ypos]*(1-range)//*igwave[xpos][ypos]		//040511	
	//print upperlimit
	//print lowerlimit		
	variable i,j
	variable isSingle=1
	for (j=-1;j<2;j+=1)
		for (i=-1;i<2;i+=1)
			if ((i!=0) || (j!=0)) 
				if ( ((xpos+i)<0) || ((xpos+i)>(width-1)) || ((ypos+j)<0) || ((ypos+j)>(height-1)) )
				else
					if ((lowerlimit<igwave[xpos+i][ypos+j]) && (igwave[xpos+i][ypos+j]<upperlimit))
						isSingle=0
						break
					endif
				endif
				//printf "x %g y %g\r",(xpos+i),(ypos+j)
			endif
		endfor
	endfor
	return isSingle
END	

Function V_createFilterSinglePixSignal()
	String curDF=GetDataFolder(1)
	if (!DataFolderExists(":GraphParameters"))
		InitGraphParameters()
	endif
	wave  src2Dwave=VX	
	SetDataFolder :GraphParameters
		Duplicate/O src2Dwave singlepixFilter
	SetDataFolder curDF		
END

// call: V9_applySinglePixRemovefilter()
Function V_filterSinglePixSignal(img_w,range)		//within the current folder
	wave img_w
	variable range
	variable width=Dimsize(img_w,0)
	variable height=Dimsize(img_w,1)
	if (height==0)
		abort "not a 2D image"
	endif
	variable countSingle=0
	wave/z singlepixFilter=:GraphParameters:singlepixFilter
	if (waveexists(singlepixFilter)==0)	
		V_createFilterSinglePixSignal()
		wave/z singlepixFilter=:GraphParameters:singlepixFilter
	endif	
	singlepixFilter=1
	variable offsetX=0
	variable offsetY=0
	NVAR unit=unit
	if (unit==3)		
		offsetX=1
		offsetY=1	
	endif	
	singlepixFilter[][]=( (V_filterCheckSurround2D(img_w,(p+offsetX),(q+offsetY),range,width,height)==1) ? 0 : 1)
	
//	variable i,j
//	for (j=0;j<height;j+=1)
//		for (i=0;i<width;i+=1)
//			if (V_filterCheckSurround2D(img_w,i,j,range,width,height))
//				singlepixFilter[i][j]=0
//				countSingle+=1
//			endif
//		endfor			
//	endfor
	//print countSingle
END