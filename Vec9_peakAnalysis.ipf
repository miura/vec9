#pragma rtGlobals=1		// Use modern global access method.


//		Coded on 021212 by Kota Miura
//		to analyze the directionality, randomness of the peaks should be quantified.
//		This algorithm calculates the sigma of the gaps between the histogram bins
//		and compare its value. histogram is then smoothed. 
//		smoothing causes radical decrease in the gap-sigma value if the distribution is random.

//		"confiness" is caliculated as following;
//		calculate sigma-gap without smoothing (GapNS)
//		calculate sigma-gap with smoothing 0.2 (GapS)
//		"confiness" = GapS / GapNS
//				this is calculated by the Function HistogramRandIT(currentHistName)
//
//		smoothing can be ranged and compared with its curve.
//		by Function HistogramRandPoints(currentHistName)

function NormalDistribution(myu,sigma)
	variable myu,sigma
	variable up,down
	up=e^ (-1*(  ( (x-myu)^2)/2/sigma^2))
	
	down=(2*pi)^0.5*sigma
	return up/down
end


Function Histrandomness(currentHistname,SmoothMag) 
	String currentHistname
	variable SmoothMag//=:Analysis:SmoothMag	
	
	wave currentHist=$currentHistname
	string currentHist_sm_name=currentHistname+"sm"
	Duplicate/O currentHist $currentHist_sm_name
	wave currentHist_sm=$currentHist_sm_name
	variable i,j,k
	variable Rowlength=dimsize(currenthist,0)

	for (j=0; j<rowlength; j+=1)
		if (j==0)
			i=rowlength-1
			k=j+1
		else 
			if (j==rowlength-1)
				i=j-1
				k=0
			else
				i=j-1
				k=j+1
			endif
		endif
		currenthist_sm[j]=(currenthist[j]+SmoothMag*(currenthist[i]+currenthist[k]))/(1+2*smoothMag)
	endfor
		
	string currentHist_smGAP_name=currentHistname+"smGAP"
	Duplicate/O currenthist_sm $currentHist_smGAP_name//,$currentHist_smGAPo_name
	wave currentHist_smGAP=$currentHist_smGAP_name
	
	for (i=0; i<rowlength;i+=1)
		if (i<(rowlength-1))
			currentHist_smGAP[i]=currentHist_sm[i+1]-currentHist_sm[i]			
		else 
			currentHist_smGAP[i]=currentHist_sm[0]-currentHist_sm[i]
		endif
	endfor
		
	variable Gap_sigma
	for (i=0; i<numpnts($currentHist_smGAP_name);i+=1)
		Gap_sigma+=abs(currentHist_smGAP[i])
	endfor			
	return Gap_Sigma
End


Function HistogramRandIT(currentHistName)
	String currentHistName
	Variable NoSmooth
	NoSmooth=Histrandomness(currentHistName,0) 
//	print Nosmooth
	Variable Point2smooth
	Point2smooth=Histrandomness(currentHistName,0.2)
//	print Point2smooth
	print Point2smooth/NoSmooth
	return Point2smooth/NoSmooth
END	 

Function HistogramRandPoints(currentHistName)
	String currentHistName
	Variable GapSig
//	Variable Point2smooth
	string Gapsigmaname=currentHistName+"GapSig"
	Make/N=10 $Gapsigmaname
	wave Gapsigwave=$Gapsigmaname
	variable i
	for (i=0;i<10;i+=1)
		Gapsigwave[i]=Histrandomness(currentHistName,i*0.1) 
	endfor
//	return Point2smooth/NoSmooth
END	