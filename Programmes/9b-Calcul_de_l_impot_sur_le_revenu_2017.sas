
/**************************************************************************************************************************************************************/
/*                                  							SAPHIR E2013 L2017                                       									  */
/*                                     								PROGRAMME 9b                                           								  	  */
/*                           							Calcul de l'imp�t sur le revenu 2017                             									  */
/*                                								sur les revenus 2016                                        								  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Les imp�ts sont calcul�s au niveau du foyer fiscal, � partir des cases vieillies des d�clarations fiscales de la table foyer. Pour les individus � non     */
/* appari�s � un traitement particulier est r�alis� � travers le calcul d�un imp�t simplifi� (programme 10).  												  */
/* L�imp�t sur le revenu est calcul� sur la base des d�clarations d�imp�t sur le revenu 2013 (ERFS 2013) en appliquant la l�gislation en vigueur pour l�imp�t */
/* sur le revenu. Les revenus consid�r�s sont ceux de l'ann�es N-1.																							  */
/*																																							  */
/* Contrairement aux autres transferts, l�unit� de r�f�rence (foyer fiscal) n�est pas reconstruite : les foyers fiscaux retenus sont ceux qui correspondent   */	
/* aux d�clarations fiscales de la DGFiP. La composition des foyers fiscaux, qui peut faire l'objet de strat�gies d'optimisation, est donc celle de l'ERFS et */
/* n'est pas modifi�e dans Saphir. Les d�clarations fiscales contiennent des informations sur les cr�dits et r�ductions d'impots (heures de travail, salaires */
/* vers�s pour les services � la personne...). Ces cr�dits et r�ductions d'impot pr�sents dans l ERFS ne sont pas modifi�s pour adapter les donn�es � l'ann�e */
/* voulue car les choix et comportement d'optimisation ne sont pas pr�visibles. 																			  */
/*																																							  */
/* Ce prorgamme calcule l'impot d� en 2017 sur les revenus de 2016 en utilisant les macros d�finies dans le programme 8b.									  */
/* Il calcule �galement les cotisations et contributions sociales sur les revenus du capital.																  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                  										1. MESURES NOUVELLES PLF 2017                         											  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%let evol_bareme=1.001; /*pr�vision d'inflation 2017 du RESF 2017*/ 
%Parametres(&evol_bareme.);

%let switch_redIR=1; 	/*r�duction d'imp�t du PLF 2017*/ 



/*Reconstitution d'une table foyer vieillie avec toutes les variables de la table initiale*/
proc sort data=saphir.foyer&acour. ; by ident&acour. idec&acour.;run;
proc sort data=scenario.foyer&acour._r&asuiv3.; by ident&acour. idec&acour.;run;
proc sort data=saphir.foyer&acour._r&asuiv4.; by ident&acour. idec&acour.;run;

data foyer&acour.rev&asuiv3.;
merge saphir.foyer&acour. scenario.foyer&acour._r&asuiv3.
    saphir.foyer&acour._r&asuiv4.(keep=ident&acour. idec&acour. _2ee _2dh)/*PFL sur revenus 2013*/; 
by ident&acour. idec&acour.;
run;


/*Calcul de l'imp�t sur les foyers FIP*/
option mprint;
%calcul_impot (annee=&asuiv3.);


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*      												II.  Ajout des informations de l'impot � la table individuelle                 					      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/*Montant PPE du foyer auquel appartient l'individu*/
proc sort data=scenario.indiv_prest; by ident&acour. declar1; run;
proc sort data=scenario.impot_fip_r&asuiv3. out=impot_fip_r&asuiv3. (rename=(declar=declar1)) nodupkey; by ident&acour. declar; run; 

data scenario.indiv_prest (compress = yes); 
length declar1 $ 79;
merge scenario.indiv_prest (in=a) impot_fip_R&asuiv3. (keep = ident&acour. declar1 impot prel_liberatoire); 
by ident&acour. declar1; 
if a;

if ppe=. then ppe=0;
if impot=. then impot=0;
if prel_liberatoire=. then prel_liberatoire=0;

run;

proc sort data=scenario.indiv_prest ; by ident&acour. noi; run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*      													III.  Ajout des poids m�nage � la table impot          	      									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=scenario.impot_fip_r&asuiv3.; by ident&acour. ; run; 
proc sort data=scenario.foyer&acour._r&asuiv3.; by ident&acour. ; run; 
proc sort data=scenario.menage_prest out=ident (keep = ident&acour. wprm&asuiv4.); by ident&acour. ; run; 

data scenario.impot_fip_r&asuiv3.;
    merge scenario.impot_fip_r&asuiv3.(in=a) ident; 
    by ident&acour.;
    if a;
run; 

data scenario.foyer&acour._r&asuiv3.;
    merge scenario.foyer&acour._r&asuiv3. (in=a) ident; 
    by ident&acour.;
    if a;
run; 


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*  													IV. CSG, CRDS, Cotisations sociales sur les revenus du patrimoine 									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%macro cotis_pat(an=);

/*Revenus au bar�me*/
data cotis_pat&an. (keep=ident&acour. CSG_cap&an. CRDS_cap&an. PS_cap&an.);
set  scenario.impot_fip_r&an. (keep= ident&acour. _1aw _1bw _1cw _1dw _2go _2dc _2fu _2ch 
_2ts _2tr _2cg _2bh _4ba _4bb _4bc _4bd _4be _3vj _3vk _5hy _5iy _5jy
_5hg _5ig _3va _3vh _3vg _3vf _3vi
_3vl _3vm _3vb _3vb _3vp _8tl _3sg _3sl _3vd _3sd _3si  _3sf _3sj _3sk _3vt
_1tv _1uv _1tw _1uw _1tx _1ux _1tt _1ut
BNCNPnet  BICNPnet _5NB _5OB _5PB _5NH _5OH _5PH _5NN _5ON _5PN _5HK 
_5IK _5JK _5KK _5LK _5MK _5TH _5UH _5VH
);



/**************************************************************************************************************************************************************/
/*				1-   Revenus du patrimoine soumis aux contributions et pr�l�vements sociaux;																  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Rentes viag�res � titre on�reux	                                                                                                                  */
/**************************************************************************************************************************************************************/

    RvA&an.=round((_1aw)*0.7);
    RvB&an.=round((_1bw)*0.5);
    RvC&an.=round((_1cw)*0.4);
    RvD&an.=round((_1dw)*0.3);
    RVTO&an.=sum(RvA&an.,RvB&an.,RvC&an.,RvD&an.);


/**************************************************************************************************************************************************************/
/*		b. Revenus de capitaux mobiliers (RCM)                                                                                                                */
/**************************************************************************************************************************************************************/    

	RCM&an.=max(0, sum(_2dc, _2fu, _2ch,_2ts, _2tr, -_2cg, -_2bh));


/**************************************************************************************************************************************************************/
/*		c. Revenus fonciers					                                                                                                                  */
/**************************************************************************************************************************************************************/

    IF _4BA>0 or _4BB>0 or _4BC>0 THEN DO;
        /*On impute les d�ficits au prorata sur _4BA*/
        IF ( round(_4BA)-_4BB-_4BC)>0 THEN DO;
        /*Les d�ficits ant�rieurs (BD) viennent apr�s le reste*/
        _4BAnet=max(0,round(_4BA)-round((_4BB+_4BC+_4BD)));     
        RFnetHorsQuotient&an.=_4BAnet;      
        END;

        ELSE DO;/*4BC est imputable sur le revenu global*/
        IF (_4BA)>0 THEN DO;
        _4BAnet=max(0,round(_4BA)-round(_4BB))-round(_4BC);     
        RFnetHorsQuotient&an.=_4BAnet;      
        END;

        ELSE DO;
        RFnetHorsQuotient&an.=-_4BC;
        END;
    END;    


    END;
    /*Le micro-foncier (BE) exclut l'application de deficits de l'annee (4BB et 4BC)(et est incompatible avec _4BA). 
    Mais les deficits des annees anterieurs peuvent etre imputes sur les revenus nets determines selon le regime micro-foncier*/
    ELSE DO;
        RFnetHorsQuotient&an.=max(0,round(_4BE*0.7-_4BD));
    END;

    RF&an.=RFnetHorsQuotient&an.;


/**************************************************************************************************************************************************************/
/*		d. Gains de cessions taxables en salaires : gains divers soumis � l'IR au taux progressif                     					                      */
/**************************************************************************************************************************************************************/

	GTS&an.=_3vj+_3vk; /*devrait �tre compt� avec les salaires -> CSG � 7,5%*/


/**************************************************************************************************************************************************************/
/*		e. Revenus des professions non salari�es                                                                                                              */
/**************************************************************************************************************************************************************/

	BENEF&an.=_5hy+_5iy+_5jy;


/**************************************************************************************************************************************************************/
/*		f. Plus-values et gains divers		                                                                                                                  */
/**************************************************************************************************************************************************************/

/*Plus-values des professions non salari�es*/
    PvProV&an.=_5hg;
    PvProC&an.=_5ig;
    PvProf&an.=sum(PvProV&an.,PvProC&an.);

/*Plus-values, gains en capital et profits divers soumis � l'IR � un taux forfaitaire*/
    PVcsg&an. = _3vg + _3sg + _3sl + _3va + _3vd + _3sd + _3vi + _3si + _3vf + _3sf + _3sj + _3sk + _3vl + _3vm + _3vt ;
    
/*Plus-values de cessions de titres de jeunes entreprises innovantes*/
    PVJEI&an.=0;

/*Total des plus-values et gains divers*/
    pv_aga&an. = _1tv + _1uv + _1tw + _1uw + _1tx + _1ux + _1tt + _1ut ; 
    PVGDIV&an.=sum(PvProf&an.,PVcsg&an.,PVJEI&an.);

/*BIC et BNC non professionnels*/
    bic_bnc_np = BICNPnet + BNCNPnet;

/*BIC BNC non professionels exon�r�s*/
    bicNPexo = sum(_5NB, _5OB, _5PB, _5NH, _5OH, _5PH, _5NN, _5ON, _5PN);
    bncNPexo = sum(_5HK, _5IK, _5JK, _5KK, _5LK, _5MK, _5TH, _5UH, _5VH);
              
    bic_bnc_np_exo = sum(bicNPexo,bncNPexo);


/**************************************************************************************************************************************************************/
/*				2- Base des contribution et pr�l�vements sociaux;																							  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*		a. Base de la CSG					                                                                                                                  */
/**************************************************************************************************************************************************************/

	BaCSG&an.=sum(RVTO&an.,RCM&an.,RF&an.,BENEF&an.,PVGDIV&an., bic_bnc_np_exo);

/**************************************************************************************************************************************************************/
/*		b. Base de la CRDS						                                                                                                              */
/**************************************************************************************************************************************************************/

    BaCRDS&an.=sum(BaCSG&an.);

/**************************************************************************************************************************************************************/
/*		c. Base du pr�l�vement social et de la contribution additionnelle                                                                                     */
/**************************************************************************************************************************************************************/

    BaPS&an.=BaCSG&an.;


/**************************************************************************************************************************************************************/
/*				3- Montant des contributions et pr�l�vements sociaux																	  					  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Montant des contributions et pr�l�vements sociaux					                      		                                                  */
/**************************************************************************************************************************************************************/

	Icsg&an.=round(BaCSG&an.*&&tx_CSG_cap&an.);
    Icrds&an.=round(BaCRDS&an.*&&tx_crds&an.);
    Ips&an.=round(BaPS&an.*&&tx_PS_cap&an.);


/**************************************************************************************************************************************************************/
/*		b. Montant net des contributions et pr�l�vements sociaux					                                                                          */
/**************************************************************************************************************************************************************/

/*Cr�dit d'imp�t �gal au montant de l'imp�t fran�ais (CSG, CRDS, PS et CA) pour les revenus de source �trang�re imposables en France*/
    CSGci&an.=max(0,Icsg&an.); 
    CRDSci&an.=max(0,Icrds&an.);
    PSci&an.=max(0,Ips&an.);


/**************************************************************************************************************************************************************/
/*		c. D�duction de l'impot social provisoire : montant net des impositions d�finitives		      		                                                  */
/**************************************************************************************************************************************************************/

    CSGdefi&an.=CSGci&an.;
    CRDSdefi&an.=CRDSci&an.;
    PSdefi&an.=PSci&an.;


/**************************************************************************************************************************************************************/
/*		d. Montant net � payer																	      		                                                  */
/**************************************************************************************************************************************************************/

    if (sum(CSGdefi&an.,CRDSdefi&an.,PSdefi&an.))>=&&plaf_imposable&an. then do;
        CSG_cap&an.=CSGdefi&an.;
        CRDS_cap&an.=CRDSdefi&an.;
        PS_cap&an.=PSdefi&an.;
    end;
    else do;
        CSG_cap&an.=0;
        CRDS_cap&an.=0;
        PS_cap&an.=0;
    end;

run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*  													V. Agr�gation des nouveux revenus par m�nage					 									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=cotis_pat&an.;by ident&acour.;run;

proc means data =cotis_pat&an. noprint;
by ident&acour.;
var CSG_cap&an. CRDS_cap&an. PS_cap&an.;
output out=somme_men&an. (drop = _TYPE_ _FREQ_) sum=;
run;

%mend;

%cotis_pat(an=&asuiv3.); /*2016*/

%macro cotis_plac (an=);

/*Revenus hors bar�me*/
data cotis_plac&an. (keep=ident&acour. CSG_plac&an. CRDS_plac&an. PS_plac&an.);
set saphir.menage_saphir;
if produitfin>0 then part_imposable = (celm + pelm  + assviem + peam)/produitfin;
else part_imposable=0;

PS_plac&an=&&tx_PS_source&an.*part_imposable*produitfin&an.; 
CSG_plac&an=&&tx_CSG_cap&an.*part_imposable*produitfin&an.; 
CRDS_plac&an.=&&tx_CRDS&an.*part_imposable*produitfin&an.; 
run;

%mend ; %cotis_plac (an=&asuiv4.) ; /*2017*/


/*Ajout � la table MENAGE_PREST*/
data scenario.menage_prest;
merge scenario.menage_prest 
somme_men&asuiv3.(keep=ident&acour. CSG_cap&asuiv3. CRDS_cap&asuiv3. PS_cap&asuiv3.) 
cotis_plac&asuiv4.(keep=ident&acour. CSG_plac&asuiv4. CRDS_plac&asuiv4. PS_plac&asuiv4.);
by ident&acour.;
run;

proc datasets library=work;delete somme_men&asuiv3. cotis_plac&asuiv4. cotis_pat&asuiv3. cotis&asuiv3. 
                                  ident impot_fip_R&asuiv3. foyer&acour.rev&asuiv3.;run; quit;


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/


