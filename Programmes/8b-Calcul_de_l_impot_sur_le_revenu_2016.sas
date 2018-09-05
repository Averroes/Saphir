

/**************************************************************************************************************************************************************/
/*                                  								SAPHIR E2013 L2017                                        								  */
/*                                     									PROGRAMME 8b                                           								  */
/*                           					Calcul de l'imp�t sur le revenu 2016 sur les revenus 2015                           						  */ 
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
/* vers�s pour les services � la personne...). Ces cr�dits et r�ductions d'imp�t pr�sents dans l'ERFS ne sont pas modifi�s pour adapter les donn�es � l'ann�e */
/* voulue car les choix et comportement d'optimisation ne sont pas pr�visibles. 																			  */
/*																																							  */
/* Ce programme calcule l'impot d� en 2015 et 2016. Les principales �tapes sont :																			  */
/* 		- Reconstruction et retraitement des variables fiscales.																							  */
/* 		- Calcul du revenu net global imposable.																											  */
/* 		- Calcul de l'imp�t.																																  */
/* 		- Calcul des r�ductions et cr�dits d imp�t.																											  */
/*																																							  */
/* Les macros d�finies servent �galement au calcul de l'impot 2017 dans le programme 9b. 																	  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                             												I. Macros                                  										  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Macro %Bareme : calcul des tranches de l'imp�t sur le revenu, quel que soit le nombre de tranches										  */
/**************************************************************************************************************************************************************/

%macro Bareme(qf, rev, npart, out_var, nb_tranches = 4); 
    if &qf. <= &bar_seuil_1. then &out_var. = 0 ;
    %let bar_ordo_1 = %SYSEVALF(%SYSFUNC(CEIL(100*(&bar_seuil_1.*&bar_taux_1.)))/100) ;     

    %do k1 = 2 %to &nb_tranches ; 
        %let k0 = %SYSEVALF(&k1 - 1) ; 
        %let bar_ordo_&k1 = %SYSEVALF(%SYSFUNC(CEIL(100*(&&bar_seuil_&k1.*&&bar_taux_&k1. - &&bar_seuil_&k1.*&&bar_taux_&k0. + &&bar_ordo_&k0.)))/100);/*P0700*/
        else if &qf. <= &&bar_seuil_&k1. then &out_var = round(&&bar_taux_&k0.*&rev.-&&bar_ordo_&k0.*&npart.) ;
        %if &k1 = &nb_tranches %then %do ; 
            else &out_var. =round(&&bar_taux_&k1.*&rev. - &&bar_ordo_&k1.*&npart.) ;
        %end ;
    %end ;
%mend Bareme ; 


/**************************************************************************************************************************************************************/
/*				2- Macro %Tranche : calcul des tranches de l'imp�t sur le revenu, quel que soit le nombre de tranches										  */
/**************************************************************************************************************************************************************/

%macro Tranche(assiette, out_var, nb_tranches = 4); 
    &out_var = 0;
    %do k0 = 1 %to &nb_tranches ;
        if  &assiette >= &&bar_seuil_&k0 then &out_var = &k0 ;
    %end;
%mend Tranche ; 


/**************************************************************************************************************************************************************/
/*				3 - Macro %part_imputee : calcul de la part imput�e d'une r�duction ou d'un cr�dit d'imp�t													  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* - impot : nom de la variable sur laquelle on souhaite imputer un credit ou une r�duction d imp�t															  */
/* - reduction de la variable que l'on souhaite imputer																										  */	
/* Cette fonction retourne une variable dont le nom est le nom du second argument auquel on ajoute le suffixe _impute										  */
/**************************************************************************************************************************************************************/

%macro part_imputee(impot,reduction) ;
    &impot._2 = max(&impot. - &reduction.,0) ;
    &reduction._impute = &impot. - &impot._2 ;
    &impot. = &impot._2 ; 
%mend part_imputee;


/**************************************************************************************************************************************************************/
/*				4- Macro Baremisation : passage au bar�me des dividendes (_2da) et des int�r�ts (_2ee), et des plus-values (_3vg) et calcul de l'acompte	  */
/**************************************************************************************************************************************************************/
     
/**************************************************************************************************************************************************************/
/* - On ajoute _2da � _2dc et on met _2da � 0																												  */
/* - On ajoute _2ee � _2tr et on met _2ee � 0 																												  */
/* - On cree _Rvg avec la valeur de _3vg et on met _3vg � 0 																								  */
/* Si le revenu fiscal de ref�rence de l'ann�e pr�c�dente est sup�rieur � 50000 �, on suppose que tous les foyers optent pour le non paiement de l'acompte    */ 
/**************************************************************************************************************************************************************/

%macro Baremisation_Rcm(switch_int = 0, switch_div = 0, switch_pv = 0, switch_av = 0);
PFO = 0 ;
impot_forf_int = 0 ;

/*z8yr: revenu fiscal de r�f�rence 2014 => non dispo dans l'ERFS, donc on prend le RFR de l'ann�e des revenus*/
no_opt_out_div  = ((matn in ('1','6')) and (mnrvkh > 75000)) or ((matn in ('2','4','3')) and (mnrvkh > 50000));
no_opt_out_int  = ((matn in ('1','6')) and (mnrvkh > 50000)) or ((matn in ('2','4','3')) and (mnrvkh > 25000));

/*Bar�misation des dividendes*/
%if &switch_div %then %do ; 
    _2dc = sum(_2dc, _2da) ; 
    _2bh = sum(_2bh, _2da) ; /*prise en compte de la d�ductibilit� de la CSG*/
    _2da = 0 ;
    if no_opt_out_div and &creation_PFO. then PFO = sum(PFO, &taux_PFO_div.*_2dc) ;
%end;

/*Bar�misation des int�rets*/
%if &switch_int %then %do ;

/*On ne bar�mise que les personnes au PFL d�clarant plus de 2000, les autres peuvent rester au PFL*/
    if sum(_2tr, _2ts, _2ee) > 2000 then do ;
        _2tr = sum(_2tr, _2ee) ;
        _2bh = sum(_2bh, _2ee) ;
        _2ee = 0 ; 
    end;
    else do;
        impot_forf_int = &taux_impot_forf.*_2ee ;
    end ;
    if no_opt_out_int and &creation_PFO. then PFO = sum(PFO, &taux_PFO_int.*sum(_2tr, _2ts)) ;  
    if &creation_PFO. then PFO = sum(PFO, &taux_PFO_int.*_2ee) ;                              
%end;

/*Bar�misation des plus values*/
zrvg = 0;
znvg = 1;

%if &switch_pv %then %do ;
    zrvg =  _3vg*(1-&pv_abat.) ; 				/*plus values apr�s abattement proportionnel*/
    if zrvg ne 0 then  znvg = &quotient_pv. ; 	/*on applique un quotient de 4*/
    _2bh = sum(_2bh, _3vg) ;
    _3vg = 0 ;
%end ;

%if &switch_av %then %do ;
    av_baremisee = max(_2dh-&max_av_pfl.*((matn in ('1','6'))+1), 0) ;
    _2ch = _2ch + av_baremisee ; 				/*plus values apr�s abattement proportionnel*/
    _2dh = _2dh - av_baremisee ;
%end ;

/*Calcul du PFL*/
PFL = sum(&pfl_div.*_2da, max(&pfl_int.*_2ee,impot_forf_int) , &pfl_avi.*_2dh) ; 

%mend Baremisation_Rcm;




/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                  												II. Calcul de l'imp�t                     												  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/*Reconstitution d'une table foyer vieillie avec toutes les variables de la table initiale*/
proc sort data=scenario.foyer&acour._r&asuiv2.; by ident&acour. idec&acour.;run;
proc sort data=saphir.foyer&acour._r&asuiv3.; by ident&acour. idec&acour.;run;

data foyer&acour.rev&asuiv2.;
merge scenario.foyer&acour._r&asuiv2.
    saphir.foyer&acour._r&asuiv3.(keep=ident&acour. idec&acour. _2ee _2dh);
by ident&acour. idec&acour.;
run;


option mprint;
%macro calcul_impot (annee=); 

%let year_rev=20&acour.; 

data scenario.impot_fip_r&annee. (compress = yes);
set foyer&acour.rev&annee.;


/**************************************************************************************************************************************************************/
/*				1 - Reconstruction des variables fiscales � partir de la variable SIF        																  */
/**************************************************************************************************************************************************************/

/*Etat matrimonial*/
mcdv=substr(sif,5,1);		  /*statut matrimonial declarant*/
mat=mcdv; 
if mat='M' then matn=1;       /*mari� (M)*/
else if mat='C' then matn=2;  /*c�libataire (C)*/
else if mat='D' then matn=3;  /*divorc� (D)*/
else if mat='V' then matn=4;  /*veuf (V)*/
else                matn=6;   /*pacs�*/ 
label matn = "Situation matrimoniale de la personne principale du foyer fiscal";

/*Mariage*/
mar=substr(sif,29,1); 
mmar=input(substr(sif,32,2),2.0);

/*Divorce*/
div=substr(sif,38,1);
mdiv=input(substr(sif,41,2),2.0);

/*Deces*/
deces=substr(sif,47,1);
mdeces=input(substr(sif,50,2),2.0);

if mmar in ('','.') then mmar=1;
if mdiv in ('','.') then mdiv=1;
if mdeces in ('','.') then mdeces=1;

else if (deces="Z" and matn=1) then nbsljj=(mdeces-1)*30;
else if (deces="Z" and matn in (2,3,4)) then nbsljj=(12-mdeces+1)*30;
else nbsljj=360;

if nbsljj=0 then nbsljj=1;

/*Annee de naissance du declarant et du conjoint*/
vousconj=substr(sif,6,4)!!"-"!!substr(sif,11,4);    /*annee de naissance du declarant, tiret, annee de naissance du conjoint*/
aged=input(substr(vousconj,1,4),4.0);               /*annee de naissance du declarant sur 3 positions*/
agec=input(substr(vousconj,6,4),4.0);               /*annee de naissance du conjoint  sur 3 positions*/
/*Si pas de conjoint, agec=9999*/

/*Variables servant � calculer les demi-parts supplementaires*/
EFGKLPSWNT=substr(sif,16,14);
/*xyz=substr(sif,34,27);*/          /*�v�nement dans l'annee X00 si mariage, 0Y0 si divorce, 00_ si deces*/
se=substr(EFGKLPSWNT,1,1);          /*enfants majeurs non compt�s a charge (si c�libataire, divors� ou veuf (CDV))*/
sf=substr(EFGKLPSWNT,2,1);          /*pension ou CI(80%) de l epouse (si mari�) ou du conjoint decede en 06 (si veuf)*/
sg=substr(EFGKLPSWNT,3,1);          /*pension de veuve de guerre (si veuf)*/
sl=substr(EFGKLPSWNT,4,1);          /*un enfant(s) a charge du conjoint decede*/
sp=substr(EFGKLPSWNT,5,1);          /*pension ou CI(80%) du d�clarant (du mari si mari�)*/
ss=substr(EFGKLPSWNT,6,1);          /*un des epoux a plus de 75 ans et carte ancien combattant*/
sw=substr(EFGKLPSWNT,7,1);          /*declarant (ou conjoint d�c�d� si veuve) CDV de plus de 75 ans et ancien combattant*/
sn=substr(EFGKLPSWNT,8,1);          /*personne ne vivant pas seule*/
st=substr(EFGKLPSWNT,9,1);          /*parent isole*/

if se="E" then _E=1; else _E=0;
if sf="F" then _F=1; else _F=0;
if sg="G" then _G=1; else _G=0;
if sl="L" then _L=1; else _L=0;
if sp="P" then _P=1; else _P=0;
if ss="S" then _S=1; else _S=0;
if sw="W" then _W=1; else _W=0;
if sn="N" then _N=1; else _N=0;
if st="T" then _T=1; else _T=0;
if deces="Z" then _Z=1; else _Z=0;


		/** Calcul du nombre de parts � partir des cases des d�clarations **/

/*nbenf de la forme F02G00R00J00N00H00I00P00 si seulement 2 enfants*/
nbenf=substr(sif,60,24);                /*enfants ou autres personnes a charge par categorie*/
nbf=input(substr(nbenf,2,2),2.0);       /*enfants*/
nbg=input(substr(nbenf,5,2),2.0);       /*(dont) enfants invalides*/
nbr=input(substr(nbenf,8,2),2.0);       /*adultes invalides*/
nbj=input(substr(nbenf,11,2),2.0);      /*enfants majeurs c�libataires demandant leur rattachement*/
nbn=input(substr(nbenf,14,2),2.0);      /*enfants majeurs mari�s demandant leur rattachement*/
nbefah=input(substr(nbenf,17,2),2.0);   /*enfants en r�sidence altern�e*/
nbefai=input(substr(nbenf,20,2),2.0);   /*enfants infirmes en r�sidence altern�e*/
nbefap=input(substr(nbenf,23,2),2.0);   /*petits enfants rattach�s en r�sidence altern�e*/

if nbf in ('','.') then nbf=0;
if nbg in ('','.') then nbg=0;
if nbr in ('','.') then nbr=0;
if nbj in ('','.') then nbj=0;
if nbn in ('','.') then nbn=0;
if nbefah in ('','.') then nbefah=0;
if nbefai in ('','.') then nbefai=0;
if nbefap in ('','.') then nbefap=0;

F=sum(nbf,0);
G=sum(nbg,0);
R=sum(nbr,0);
J=sum(nbj,0);
N=sum(nbn,0);
H=sum(nbefah,0);
I=sum(nbefai,0);
P=0;

npcha=sum(nbf,nbr,nbj);                 /*tous sauf enfants majeurs maries*/
npchai=sum(nbg,nbr);                    /*invalides*/



/**************************************************************************************************************************************************************/
/*				2 - Cr�ation d'indicatrices et retraitement de la situation familiale du d�clarant pour calculer le nombre de parts au sein du foyer   	  */
/**************************************************************************************************************************************************************/

    zEn = _E ;
    zFn = _F ; 
    zGn = _G ; 
    zLn = _L ;  
    zPn = _p ;  
    zSn = _S ;  
    zWn = _W ;
    zNn = _N ;
    zTn = _T ;

    zXn = 0 ; /*variable non disponible dans l'ERFS*/ 
    zYn = 0 ; /*variable non disponible dans l'ERFS*/
    zZn = _Z ;

    if &demi_part_vieux. = 0 then zEn = 0;
  
    
    /* Contr�les */
	/*Si on n'a pas encore 75 ans, ou si on n'a pas de conjoint de plus de 75 ans d�c�d� dans l'ann�e, on ne peut pas cocher la case W*/
    if (&year_rev.-ageD < 75) and (zZn=0) then zWn = 0 ;
	/*Si on n'est pas mari� ou pacs� ou que les deux mari�s sont ag�s de moins de 75 ans, on ne peut pas cocher la case S*/
    if ((&year_rev.-ageD < 75) and (&year_rev.-ageC < 75)) or (matn not in (1 6)) then zSn = 0 ;


/**************************************************************************************************************************************************************/
/*				3 - Calcul de l'�ge du d�clarant et du conjoint + personnes du foyer 																		  */
/**************************************************************************************************************************************************************/

    anaisenf=compress(anaisenf);                    /*anaisenf de la forme FaabbG R J N si seulement 2 enfants n�s en aa et bb*/
    array ageF {&nb_enf_max.};                      /*ann�e de naissance des enfants cases F*/                        
    IF anaisenf = '.' THEN DO;
        DO iter=1 TO &nb_enf_max.;
        ageF(iter)=0;
        END;
    END;
    ELSE DO;
      DO ind=1 TO &nb_enf_max.; 
      lettre=substr(anaisenf,5*ind-4,1); 
      if lettre = 'F' then ageF(ind)=substr(anaisenf,5*ind-3,4);
      else ageF(ind)=0;
      END;
    END;

    AGE1 = &year_rev. - AGED; 
    if matn in (1,6) then AGE2 = &year_rev. - AGEC;
    else AGE2 = 0 ;

    array anais {&nb_enf_max.} ageF01-ageF08;

    label   AGE1   = "Age du d�clarant"
            AGE2   = "Age du conjoint"
            ageF01 = "Age de la premi�re PAC"
            ageF02 = "Age de la deuxi�me PAC"
            ageF03 = "Age de la troisi�me PAC"
            ageF04 = "Age de la quatri�me PAC" ; 

    /*Renommage des variables DGFIP sur le nombre d'enfants selon les diff�rentes situations familiales*/
    nI = I ;


/**************************************************************************************************************************************************************/
/*				4- Retraitement des revenus d�clar�s 																										  */ 
/**************************************************************************************************************************************************************/

/*Bar�misation des revenus du capital*/
PFO=0; 
PFL=0;

    /*Cr�ation de vecteurs de variables*/
    array pecdef{2} pecdef1-pecdef2;
        pecdef1=0;
        pecdef2=1;

        label pecdef1 ="Non prise en compte des d�ficits pour l'imposition des revenus 2010 (hors d�ficits ant�rieurs)" 
              pecdef2 ="Prise en compte pour l'imposition des revenus 2010 (hors d�ficits ant�rieurs)" ;  
        
    array BAimposable{2};
    array BA{2};
    array BICPtax{2};
    array BICNPtax{2};
    array BIC{2};
    array BNCPtax{2};
    array BNCNPtax{2};
    array BNCSPENP{2};
    array BNC{2};
    array RFB{2};
    array PVPRO{2};
    array PVNPRO{2};
    array PV{2};
    array Declare{2} Declare1-Declare2;
    array DeclareHorsExcepPV{2} DeclareHorsExcepPV1-DeclareHorsExcepPV2;

    do iter=1 to 2;

		/** Salaires **/ 
        SAL                 =   _1AJ + _1BJ + _1CJ + _1DJ + _1EJ + _1FJ +
                                _1AU + _1BU + _1CU + _1DU /*heures suppl�mentaires exon�r�es r�alis�es en 2012 et pay�es en 2013*/
                                /*les heures suppl�mentaires sont prises en compte dans le revenu d�clar�, m�me si non imposable*/ 
                              + _1AQ + _1BQ + _1DY + _1EY + _1LZ + _1MZ;

        label SAL           =   "Montant de salaire d�clar� (y.c heures sup) hors syst�me du quotient (�)" ; 


		/** Allocations ch�mage ou pr�retraite **/ 
       CHO_PreRET           =   _1AP + _1BP + _1CP + _1DP + _1EP + _1FP ; 
       label CHO_PreRET     =   "Montant des pr�retraites et allocations ch�mage (�)" ; 


		/** Pensions **/ 
        PEN                 =   _1AS + _1BS + _1CS + _1DS + _1ES + _1FS
                              + _1AO + _1BO + _1CO + _1DO + _1EO + _1FO; 
        label PEN           =   "Montant des pensions d�clar�es hors syst�me du quotient (�)" ; 

		/** Rentes viag�res � titre on�reux (RVTO) **/
        RVTO                =   _1AW + _1BW + _1CW + _1DW;
        label RVTO          =   "Montant des RVTO hors syst�me du quotient (�)" ; 

		/** B�n�fices Agricoles (BA) **/
        BAexo               =   _5HB + _5IB + _5JB + _5HH + _5IH + _5JH + _5HN + _5IN + _5JN;
        label BAexo         =   "Montant des b�n�fices agricoles exon�r�s (�)" ;

        BAimposable{iter}   =   _5HC + _5IC + _5JC 
                              + _5HI + _5II + _5JI 
                              + _5HO + _5IO + _5JO
                              + _5HW + _5IW + _5JW
                              - pecdef{iter}*(_5HF + _5IF + _5JF + _5HL + _5IL + _5JL);

        label BAimposable1  =   "Montant des b�n�fices agricoles imposables, sans prise en compte des d�ficits(�)"
              BAimposable2  =   "Montant des b�n�fices agricoles imposables, avec prise en compte des d�ficits(�)" ; 

        BA{iter}            =   BAexo + BAimposable{iter};
        label BA1           =   "Montant des b�n�fices agricoles totaux (exon�r�s et imposables), sans prise en compte des d�ficits (�)" 
              BA2           =   "Montant des b�n�fices agricoles totaux (exon�r�s et imposables), avec prise en compte des d�ficits (�)" ;

		/** B�n�fices industriels et commerciaux (BIC) **/ 

	/*BIC professionnels au r�gime de l auto-entrepreneur : ventes de marchandises, prestations de services*/  
        TAtax = round((_5TA-((_5TA* &auto_vente_abat.)))<>0); 
        UAtax = round((_5UA-((_5UA* &auto_vente_abat.)))<>0); 
        VAtax = round((_5VA-((_5VA* &auto_vente_abat.)))<>0); 
        TBtax = round((_5TB-((_5TB* &auto_service_abat.)))<>0); 
        UBtax = round((_5UB-((_5UB* &auto_service_abat.)))<>0); 
        VBtax = round((_5VB-((_5VB* &auto_service_abat.)))<>0); 

        BICPAE              =   TAtax+UAtax+VAtax+TBtax+UBtax+VBtax;
        label BICPAE        =   "Montant total des BIC pro d�clar�s au r�gime de l'auto-entrepreneur (�)" ; 


	/* BIC professionnels et non professionnels (tous r�gimes) : exon�r�s et imposables*/ 
        BICexo              =   _5KB + _5LB + _5MB + _5NB + _5OB + _5PB
                              + _5KH + _5LH + _5MH + _5NH + _5OH + _5PH
                              + _5KN + _5LN + _5MN + _5NN + _5ON + _5PN;

        label BICexo        =   "Montant total des BIC pro et non pro exon�r�s (r�gime simplifi� et r�gime r��l)(�)" ; 

        BICPtax{iter}       =   _5KC + _5LC + _5MC + _5KI + _5LI + _5MI + 
                                _5KX + _5LX + _5MX - pecdef{iter}*(_5KF + _5LF + _5MF + _5KL + _5LL + _5ML ); 
    
        label BICPtax1      =   "Montant total des BIC pro imposables (r�gime simplifi� et r�gime r��l), hors d�ficits (�)"
              BICPtax2      =   "Montant total des BIC pro imposables (r�gime simplifi� et r�gime r��l), avec d�ficits (�)" ;

        BICNPtax{iter}         =   _5NC + _5OC + _5PC + _5NI + _5OI + _5PI +  _5NX + _5OX + _5PX
                                -  pecdef{iter} * (_5NF + _5OF + _5PF + _5NL + _5OL + _5PL + _5IU);
        label BICNPtax1     =   "Montant total des BIC non pro imposables (r�gime simplifi� et r�gime r��l), hors d�ficits (�)"
              BICNPtax2     =   "Montant total des BIC non pro imposables (r�gime simplifi� et r�gime r��l), avec d�ficits (�)" ;

        KOtax = round((_5KO-(&auto_abat_min.<>(min(_5KO,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        LOtax = round((_5LO-(&auto_abat_min.<>(min(_5LO,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        MOtax = round((_5MO-(&auto_abat_min.<>(min(_5MO,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        KPtax = round((_5KP-(&auto_abat_min.<>(min(_5KP,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        LPtax = round((_5LP-(&auto_abat_min.<>(min(_5LP,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        MPtax = round((_5MP-(&auto_abat_min.<>(min(_5MP,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);

              BICMICP             =   KOtax + LOtax + MOtax + KPtax + LPtax + MPtax;

        label BICMICP       =   "Montant total des BIC pro imposables (r�gime de la micro-entreprise)" ; 
        NGtax = round((_5NG-(&auto_abat_min.<>(min(_5NG,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        OGtax = round((_5OG-(&auto_abat_min.<>(min(_5OG,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        PGtax = round((_5PG-(&auto_abat_min.<>(min(_5PG,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        NOtax = round((_5NO-(&auto_abat_min.<>(min(_5NO,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        OOtax = round((_5OO-(&auto_abat_min.<>(min(_5OO,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);
        POtax = round((_5PO-(&auto_abat_min.<>(min(_5PO,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0);

        NDtax = round((_5ND-(&auto_abat_min.<>(min(_5ND,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        ODtax = round((_5OD-(&auto_abat_min.<>(min(_5OD,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        PDtax = round((_5PD-(&auto_abat_min.<>(min(_5PD,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        NPtax = round((_5NP-(&auto_abat_min.<>(min(_5NP,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        OPtax = round((_5OP-(&auto_abat_min.<>(min(_5OP,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
        PPtax = round((_5PP-(&auto_abat_min.<>(min(_5PP,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);

        BICMICNP            =   NOtax + OOtax + POtax + NPtax + OPtax + PPtax;
        label BICMICNP      =   "Montant total des BIC non pro imposables (r�gime de la micro-entreprise)" ; 


        BIC{iter}              =   BICexo + BICPAE + BICPtax{iter} + BICNPtax{iter} + BICMICP + BICMICNP;
        label BIC1          =   "Montant total des BIC pro et non pro d�clar�s (tous r�gimes), hors d�ficits (�)"
              BIC2          =   "Montant total des BIC pro et non pro d�clar�s (tous r�gimes), avec d�ficits (�)" ;


		/** B�n�fices non commerciaux (BNC) **/
        TEtax=round((_5TE-((_5TE* &auto_nc_abat.)))<>0);
        UEtax=round((_5UE-((_5UE* &auto_nc_abat.)))<>0);
        VEtax=round((_5VE-((_5VE* &auto_nc_abat.)))<>0);

        BNCPAE              =   TEtax + UEtax + VEtax;
        label BNCPAE        =   "Montant total des BNC pro d�clar�s au r�gime de l'auto-entrepreneur" ; 

        BNCexo              =   _5HP + _5IP + _5JP + _5QB + _5RB + _5SB + _5QH + _5RH + _5SH
                                + _5qm +_5rm +_5th +_5uh +_5vh +_5hk +_5ik +_5jk +_5kk +_5lk +_5mk ; 
        label BNCexo        =   "Montant total des BNC pro et non pro exon�r�s";

        BNCPtax{iter}       =   _5QC + _5RC + _5SC + _5QI + _5RI + _5SI + _5HV + _5IV + _5JV 
                                - pecdef{iter}*(_5QE + _5RE + _5SE + _5QK + _5RK + _5SK + _5KZ);
        label BNCPtax1      =   "Montant total des BNC pro imposables, hors d�ficits" 
              BNCPtax2      =   "Montant total des BNC pro imposables, avec d�ficits"; 

        BNCNPtax{iter}         =   _5SN - pecdef{iter}*(_5SP+(_5HT+_5IT+_5JT+_5KT+_5LT+_5MT));
        label BNCNPtax1     =   "Montant total des BNC non pro imposables, hors d�ficits" 
              BNCNPtax2     =   "Montant total des BNC non pro imposables, avec d�ficits"; 

        HQtax = round((_5HQ-(&auto_abat_min.<>(_5HQ*&auto_nc_abat.)))<>0);
        IQtax = round((_5IQ-(&auto_abat_min.<>(_5IQ*&auto_nc_abat.)))<>0);
        JQtax = round((_5JQ-(&auto_abat_min.<>(_5JQ*&auto_nc_abat.)))<>0);

        BNCSPEP             =   Hqtax + Iqtax + Jqtax;
        label BNCSPEP       =   "Montant total des BNC pro imposables, au r�gime d�claratif sp�cial ou micro-BNC" ;  

        KUtax = round((_5KU-(&auto_abat_min.<>(_5KU* &auto_nc_abat.)))<>0);
        LUtax = round((_5LU-(&auto_abat_min.<>(_5LU* &auto_nc_abat.)))<>0);
        MUtax = round((_5MU-(&auto_abat_min.<>(_5MU* &auto_nc_abat.)))<>0);

        BNCSPENP{iter}         =   Kutax + Lutax + Mutax + _5KY + _5LY + _5MY - pecdef{iter} * _5JU ;
        label BNCSPENP1     =   "Montant total des BNC pro imposables, au r�gime d�claratif sp�cial ou micro-BNC, hors d�ficits (�)"
              BNCSPENP2     =   "Montant total des BNC pro imposables, au r�gime d�claratif sp�cial ou micro-BNC, avec d�ficits (�)" ;

        BNC{iter}              =   BNCexo + BNCPAE + BNCPtax{iter} + BNCNPtax{iter} + BNCSPEP + BNCSPENP{iter};
        label BNC1          =   "Montant total des BNC pro et non pro d�clar�s (tous r�gimes), hors d�ficits (�)"
              BNC2          =   "Montant total des BNC pro et non pro d�clar�s (tous r�gimes), avec d�ficits (�)" ;


		/** Revenus des capitaux mobiliers (RCM) **/
        RCMB                =   max(_2DC + _2FU + _2CH + _2TS + _2GO + _2TR - _2CA + _2EE + _2DH,0); 	/*_2CA correspond � des frais*/
        
        label RCMB          =   "Montant total des RCM, non soumis au syst�me du quotient (�)" ;


		/** Revenus fonciers **/
        RFB{iter}              =   _4BA - pecdef{iter}*(_4BB+_4BC+_4BD) + _4BE;
        
        label RFB1          =   "Montant total des revenus fonciers, hors d�ficits et non soumis au syst�me du quotient (�)"
              RFB2          =   "Montant total des revenus fonciers, avec d�ficits et non soumis au syst�me du quotient (�)" ;


		/** Plus-values **/
        PVPRO{iter}            =   _5HE+_5IE+_5JE + _5HX+_5IX+_5JX + 
                                _5KE+_5LE+_5ME + _5KQ+_5LQ+_5MQ - pecdef{iter}*(_5KR+_5LR+_5MR) + 
                                _5NE+_5OE+_5PE + _5NQ+_5OQ+_5PQ - pecdef{iter}*(_5NR+_5OR+_5PR) + 
                                _5QD+_5RD+_5SD + _5HR+_5IR+_5JR - pecdef{iter}*(_5HS+_5IS+_5JS) + 
                                _5KV+_5LV+_5MV  - pecdef{iter}*(_5KW+_5LW+_5MW) + 
                                _5SO;
        label PVPRO1        =   "Montant total des plus-values professionnelles, hors d�ficits (�)"
              PVPRO2        =   "Montant total des plus-values professionnelles, avec d�ficits (�)" ;


        PVNPRO{iter}           =  _3VF + _3VI + _3VL + _3VM + _3VJ + _3VK                
                                  + (_3VG - pecdef{iter} * _3VH) + _1TV + _1UV + _1TW + _1UW + _1TX + _1UX ;
        label PVPRO1        =   "Montant total des plus-values non-professionnelles, hors d�ficits (�)"
              PVPRO2        =   "Montant total des plus-values non-professionnelles, avec d�ficits (�)" ;

        PV{iter}               =   PVPRO{iter} + PVNPRO{iter};
        label PV1           =   "Montant total des plus-values, hors d�ficits (�)"
              PV2           =   "Montant total des plus-values, avec prise en compte des d�ficits (�)" ;


		/** Montant total des revenus d�clar�s **/
        Quotient            =   _0xx;
        label Quotient      =   "Montant total des revenus d�clar�s au syst�me du quotient" ; 

        Declare{iter}          =   SAL + CHO_PreRET + PEN + RVTO + BA{iter} + BIC{iter} + BNC{iter} + RFB{iter} + RCMB + PV{iter} + Quotient;
        label   Declare1    =   "Revenus d�clar�s hors d�ficits" 
                Declare2    =   "Revenus d�clar�s y compris d�ficits (hors d�ficits ant�rieurs)" ;  

        DeclareHorsExcepPV{iter}       =   SAL + CHO_PreRET + PEN+RVTO + BA{iter} + BIC{iter} + BNC{iter} + RFB{iter} + RCMB;
        label   DeclareHorsExcepPV1 =   "Revenus d�clar�s hors d�ficits, rev exceptionnels, plus-values et rev. au quotient" 
                DeclareHorsExcepPV2 =   "Revenus d�clar�s y.c. d�ficits, rev exceptionnels, plus-values et rev. au quotient(hors d�ficits ant�rieurs)" ; 

        DeficitAnterieur    =   _5QF + _5QG + _5QN + _5QO + _5QP + _5QQ + _5RN + _5RO + _5RP + _5RQ + _5RR + _5RW + _6FA + _6FB + _6FC + _6FD + _6FE + _6FL;  
        label DeficitAnterieur = "Montant total des d�ficits ant�rieurs, non pris en compte dans DECLARE et DECLAREHORSEXCEPPV" ; 
     
    end;


/**************************************************************************************************************************************************************/
/*				5 - Calcul du revenu net global imposable au niveau du foyer fiscal 																		  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*		a. Cr�ation de vecteurs de variables																					 		                      */
/**************************************************************************************************************************************************************/
    array ricalc ricalc1-ricalc2;
    array qf qf1-qf2;
    array ds ds1-ds2;
    array dsb dsb1-dsb2;
    array dsa dsa1-dsa2;
    array avQFeff avQFeff1-avQFeff2;


/**************************************************************************************************************************************************************/
/*		b. Abattement pour contribuables �g�s ou invalides																		 		                      */
/**************************************************************************************************************************************************************/
    if (age1>=&age_seuil. or zPn=1) then abtinv1=1;
    else abtinv1=0;

    if (age2>=&age_seuil. or (age2>0 & zFn=1)) then abtinv2=1;
    else abtinv2 = 0;

    abtinv = abtinv1+abtinv2;

    label   abtinv1 =   "1/0 : �ligibilit� du d�clarant � l'abat. pour contribuables �g�s ou invalides"
            abtinv2 =   "1/0 : �ligibilit� du conjoint � l'abat. pour contribuables �g�s ou invalides"
            abtinv  =   "Eligibilit� du d�clarant, du conjoint (ou les deux)� l'abattement pour contribuables �g�es ou invalides"; 


/**************************************************************************************************************************************************************/
/*		c. Calcul des unit�s de consommation au sens Insee																		 		                      */
/**************************************************************************************************************************************************************/ 
    nb14 = 0 ;
    do iter=1 to &nb_enf_max.;
        if ((anais(iter)>0)&(anais(iter)<=14)) then nb14=nb14+1;
    end;
 
    Nbpers = 0 ;
    if matn in (1,6) then nbpers = 2 + F + H/2 + J + N + R ; 
    else nbpers = 1 + F + H/2 + J + N + R ;

    
    uc = 1 + 0.5*(nbpers-1-nb14) + 0.3*nb14 ;

    label   nb14    = "Nbre d'enfants entre 0 et 14 ans au sein du foyer fiscal" 
            Nbpers  = "Nbre de personnes au sein du foyer fiscal" 
            uc      = "Unit�s de consommation du foyer fiscal"; 

    revuc1 = declare1/uc;     
    revuc2 = declare2/uc;      

    label   revuc1 = "Montant total de revenu d�clar� par uc (au sens de l'Insee)(�), hors d�ficits"
            revuc2 = "Montant total de revenu d�clar� par uc (au sens de l'Insee)(�), avec d�ficits" ; 


/**************************************************************************************************************************************************************/
/*		d. Revenu net cat�goriel : traitements et salaires, gains de cessions d'option											 		                      */
/**************************************************************************************************************************************************************/

			/*** D�clarant ***/

		/** Revenu brut (salaires, revenus de remplacement, gains de cessions d�option) **/
        tsb1        =   _1aj + _1ap + _3vj + _1tv + _1tw + _1tx + _1tt ;
        tsb2        =   _1bj + _1bp + _3vk + _1uv + _1uw + _1ux + _1ut;
        tsb3        =   _1cj + _1cp;
        tsb4        =   _1dj + _1dp;
        tsb5        =   _1ej + _1ep; 
        tsb6        =   _1fj + _1fp;

        label tsb1  =   "Montant brut (i.e. hors abat. des 10% ou frais pro) des TS et gains de cessions d'option du d�clarant" ; 
        label tsb2  =   "Montant brut (i.e. hors abat. des 10% ou frais pro) des TS et gains de cessions d'option du conjoint" ; 
        label tsb3  =   "Montant brut (i.e. hors abat. des 10% ou frais pro) des TS et gains de cessions d'option de la 1�re PAC" ; 
        label tsb4  =   "Montant brut (i.e. hors abat. des 10% ou frais pro) des TS et gains de cessions d'option de la 2�me PAC" ;
        label tsb5  =   "Montant brut (i.e. hors abat. des 10% ou frais pro) des TS et gains de cessions d'option de la 3�me PAC" ;
        label tsb6  =   "Montant brut (i.e. hors abat. des 10% ou frais pro) des TS et gains de cessions d'option de la 4�me PAC" ;
                            
		/** Des traitements et salaires bruts au revenu net cat�goriel : d�duction des frais professionnels **/  
           	/*Etape 1 : une d�duction forfaitaire de 10% de droit commun limit�e � un plafond fixe n�1*/  
            dnts1 = min(&abat_taux.*tsb1, &sal_abat_max.); 

            /*Etape 2 : la d�duction est plafonn�e (cas du ch�meur > 1 an ou non) et soumise � un plafond n� 2 (les TS si < plafond n�1)*/ 
			/*Seuil deduction de 10%, mais la deduction doit �tre inf�rieure ou �gale � tsb1*/
            if _1ai=0 then  dnts1 = min(max(dnts1, &sal_abat_min.), tsb1);
            else            dnts1 = min(max(dnts1, &cho_abat_min.), tsb1) ; 
                

            /*Etape 3 : mais, si les frais r�els sont sup�rieurs � la d�duction de 10%, ils sont d�duits � sa place*/ 
            dnts1 = max(_1ak, dnts1); 
                
            /*Etape 4 : apr�s d�duction des frais professionnels, on obtient les traitements et salaires nets (n�gatifs si frais r�els > TS)*/ 
            tsn1  = tsb1 - dnts1 ;

            /*Etape 5 : les frais professionnels sont r�partis entre les revenus ordinaires et les revenus au quotient*/ 
        if tsb1 ne 0 then do;
            tskn1 = round((_1aj+_1ap+_3vj+_1tt)*tsn1/tsb1);
            tsvn1 = round(_1tv*tsn1/tsb1);              /*Quotient de 1*/
            tswn1 = round(_1tw*tsn1/tsb1);              /*Quotient de 2*/
            tsxn1 = round(_1tx*tsn1/tsb1);              /*Quotient de 3*/
            tsjn1 = 0;         
            tspn1 = 0;         
        end;
        else do;
        	/*Etape 6 : cas des traitements et salaires nuls*/ 
            tskn1 = 0; 
            tsvn1 = 0; 
            tswn1 = 0; 
            tsxn1 = 0; 
            tsjn1 = 0; 
            tspn1 = 0; 
        end;


		/** Des traitements et salaires bruts au revenu net cat�goriel : d�duction des frais professionnels **/  
            /*Etape 1 : une d�duction forfaitaire de 10% de droit commun limit�e � un plafond fixe n�2*/  
            dnts2 = min(&abat_taux.*tsb2, &sal_abat_max.); 

            /*Etape 2 : la d�duction est plafonn�e (cas du ch�meur > 1 an ou non) et soumise � un plafond n� 2 (les traitements et salaires si < plafond n�2)*/
			/*Seuil deduction de 10%, mais la deduction doit �tre inf�rieure ou �gale � tsb2*/ 
            if _1bi=0 then  dnts2 = min(max(dnts2, &sal_abat_min.), tsb2);
            else            dnts2 = min(max(dnts2, &cho_abat_min.), tsb2) ; 

            /*Etape 3 : mais, si les frais r�els sont sup�rieurs � la d�duction de 10%, ils sont d�duits � sa place*/ 
            dnts2 = max(_1bk, dnts2); 
                
            /*Etape 4 : apr�s d�duction des frais professionnels, on obtient les traitements et salaires nets (n�gatifs si frais r�els > traitements et salaires)*/ 
            tsn2  = tsb2 - dnts2 ;

            /*Etape 5 : les frais professionnels sont r�partis entre les revenus ordinaires et les revenus au quotient*/ 
        if tsb2 ne 0 then do;
            tskn2 = round((_1bj+_1bp+_3vk +_1ut)*tsn2/tsb2);
            tsvn2 = round(_1uv*tsn2/tsb2);	/*Quotient de 1*/
            tswn2 = round(_1uw*tsn2/tsb2);	/*Quotient de 2*/
            tsxn2 = round(_1ux*tsn2/tsb2);	/*Quotient de 3*/
            tsjn2 = 0;              		/*Quotient de zNbj*/
            tspn2 = 0;              		/*Quotient de zNbp*/
        end;
        else do;
        /*Cas des traitements et salaires nuls*/
            tskn2 = 0; 
            tsvn2 = 0; 
            tswn2 = 0; 
            tsxn2 = 0; 
            tsjn2 = 0; 
            tspn2 = 0; 
        end;


			/*** Premi�re personne � charge (PAC) ***/

		/**Des traitements et salaires bruts au revenu net cat�goriel : d�duction des frais professionnels **/  
            /*Etape 1 : une d�duction forfaitaire de 10% de droit commun limit�e � un plafond fixe n�3*/  
            dnts3 = min(&abat_taux.*tsb3, &sal_abat_max.); 

            /*Etape 2 : la d�duction est plafonn�e (cas du ch�meur > 1 an ou non) et soumise � un plafond n� 3 (les traitements et salaires si < plafond n�3)*/
			/*Seuil deduction de 10%, mais la deduction doit �tre inf�rieure ou �gale � tsb3*/ 
            if _1ci=0 then  dnts3 = min(max(dnts3, &sal_abat_min.), tsb3);
            else            dnts3 = min(max(dnts3, &cho_abat_min.), tsb3) ; 

            /*Etape 3 : mais, si les frais r�els sont sup�rieurs � la d�duction de 10%, ils sont d�duits � sa place*/ 
            dnts3 = max(_1ck, dnts3); 
                
            /*Etape 4 : apr�s d�duction des frais professionnels, on obtient les traitements et salaires nets (n�gatifs si frais r�els > traitements et salaires)*/ 
            tsn3  = tsb3 - dnts3 ;

            /*Etape 5 : les frais professionnels sont r�partis entre les revenus ordinaires et les revenus au quotient*/ 
        if tsb3 ne 0 then do;
            tskn3 = round((_1cj+_1cp)*tsn3/tsb3);
            tsjn3 = 0;              /*quotient de zNcj*/
            tspn3 = 0;              /*quotient de zNcp*/
        end;
        else do;

		/*Cas des traitements et salaires nuls*/
            tskn3 = 0; 
            tsjn3 = 0; 
            tspn3 = 0; 
        end;


			/*** Deuxi�me personne � charge (PAC) ***/

		/** Des traitements et salaires bruts au revenu net cat�goriel : d�duction des frais professionnels **/  
            /*Etape 1 : une d�duction forfaitaire de 10% de droit commun limit�e � un plafond fixe n�4*/  
            dnts4 = min(&abat_taux.*tsb4, &sal_abat_max.); 

            /*Etape 2 : la d�duction est plafonn�e (cas du ch�meur > 1 an ou non) et soumise � un plafond n� 4 (les traitements et salaires si < plafond n�4)*/
			/*Seuil deduction de 10%, mais la deduction doit �tre inf�rieure ou �gale � tsb4*/  
            if _1di=0 then  dnts4 = min(max(dnts4, &sal_abat_min.), tsb4);
            else            dnts4 = min(max(dnts4, &cho_abat_min.), tsb4) ; 

            /*Etape 3 : mais, si les frais r�els sont sup�rieurs � la d�duction de 10%, ils sont d�duits � sa place*/ 
            dnts4 = max(_1dk, dnts4); 
                
            /*Etape 4 : apr�s d�duction des frais professionnels, on obtient les traitements et salaires nets (n�gatifs si frais r�els > traitements et salaires)*/ 
            tsn4  = tsb4 - dnts4 ;
                
            /*Etape 5 : les frais professionnels sont r�partis entre les revenus ordinaires et les revenus au quotient*/ 
        if tsb4 ne 0 then do;
            tskn4 = round((_1dj+_1dp)*tsn4/tsb4);
            tsjn4 = 0;              
            tspn4 = 0;              
        end;
        else do;
        	/*Cas des traitements et salaires nuls*/
            tskn4 = 0; 
            tsjn4 = 0; 
            tspn4 = 0; 
        end;


			/*** Troisi�me personne � charge (PAC) ***/

		/** Des traitements et salaires bruts au revenu net cat�goriel : d�duction des frais professionnels **/
            /*Etape 1 : une d�duction forfaitaire de 10% de droit commun limit�e � un plafond fixe n�5*/  
            dnts5 = min(&abat_taux.*tsb5, &sal_abat_max.); 

            /*Etape 2 : la d�duction est plafonn�e (cas du ch�meur > 1 an ou non) et soumise � un plafond n� 5 (les traitements et salaires si < plafond n�5)*/
			/*Seuil deduction de 10%, mais la deduction doit �tre inf�rieure ou �gale � tsb5*/ 
           if _1ei=0 then   dnts5 = min(max(dnts5, &sal_abat_min.), tsb5);
            else            dnts5 = min(max(dnts5, &cho_abat_min.), tsb5) ; 

            /*Etape 3 : mais, si les frais r�els sont sup�rieurs � la d�duction de 10%, ils sont d�duits � sa place*/ 
            dnts5 = max(_1ek, dnts5); 
                
            /*Etape 4 : apr�s d�duction des frais professionnels, on obtient les traitements et salaires nets (n�gatifs si frais r�els > traitements et salaires)*/ 
           tsn5  = tsb5 - dnts5 ;

            /*Etape 5 : les frais professionnels sont r�partis entre les revenus ordinaires et les revenus au quotient*/ 
       if tsb5 ne 0 then do;
            tskn5 = round((_1ej+_1ep)*tsn5/tsb5);
            tsjn5 = 0;
            tspn5 = 0;
       end;
        else do;
        	/*Cas des traitements et salaires nuls*/
            tskn5 = 0; 
            tsjn5 = 0; 
            tspn5 = 0; 
        end;


			/*** Quatri�me personne � charge (PAC) ***/

		/** Des traitements et salaires bruts au revenu net cat�goriel : d�duction des frais professionnels **/  
            /*Etape 1 : une d�duction forfaitaire de 10% de droit commun limit�e � un plafond fixe n�6*/  
            dnts6 = min(&abat_taux.*tsb6, &sal_abat_max.); 

            /*Etape 2 : la d�duction est plafonn�e (cas du ch�meur > 1 an ou non) et soumise � un plafond n�6 (les traitements et salaires si < plafond n�6)*/
			/*Seuil deduction de 10%, mais la deduction doit �tre inf�rieure ou �gale � tsb6*/ 
            if _1fi=0 then  dnts6 = min(max(dnts6, &sal_abat_min.), tsb6);
            else            dnts6 = min(max(dnts6, &cho_abat_min.), tsb6) ; 

            /*Etape 3 : mais, si les frais r�els sont sup�rieurs � la d�duction de 10%, ils sont d�duits � sa place*/ 
            dnts6 = max(_1fk, dnts6); 
                
            /*Etape 4 : apr�s d�duction des frais professionnels, on obtient les traitements et salaires nets (n�gatifs si frais r�els > traitements et salaires)*/ 
            tsn6  = tsb6 - dnts6 ;
                
            /*Etape 5 : les frais professionnels sont r�partis entre les revenus ordinaires et les revenus au quotient*/ 
        if tsb6 ne 0 then do;
            tskn6 = round((_1fj+_1fp)*tsn6/tsb6);
            tsjn6 = 0;
            tspn6 = 0;
        end;
        else do;
        	/*Cas des TS nuls*/
           tskn6 = 0; 
            tsjn6 = 0; 
            tspn6 = 0; 
        end;

		/** Revenus nets : traitements et salaires et gains de cessions d option **/ 
        tsn1        =  tskn1 + tsjn1 + tspn1 + tsvn1 + tswn1 + tsxn1 ; 
        tsn2        =  tskn2 + tsjn2 + tspn2 + tsvn2 + tswn2 + tsxn2 ; 
        tsn3        =  tskn3 + tsjn3 + tspn3 ; 
        tsn4        =  tskn4 + tsjn4 + tspn4 ; 
        tsn5        =  tskn5 + tsjn5 + tspn5 ; 
        tsn6        =  tskn6 + tsjn6 + tspn6 ; 

        label tsn1  =   "Montant total des TS et gains de cessions d'option nets (apr�s abat. 10% ou frais pro) du d�clarant (�)";
        label tsn2  =   "Montant total des TS et gains de cessions d'option nets (apr�s abat. 10% ou frais pro) du conjoint (�)"; 
        label tsn3  =   "Montant total des traitements et salaires nets (apr�s abat. 10% ou frais pro) de la 1�re PAC (�)"; 
        label tsn4  =   "Montant des TS et gains de cessions d'option nets (apr�s abat. 10% ou frais pro) de la 2�me PAC (�)"; 
        label tsn5  =   "Montant des TS et gains de cessions d'option nets (apr�s abat. 10% ou frais pro) de la 3�me PAC (�)"; 
        label tsn6  =   "Montant des TS et gains de cessions d'option nets (apr�s abat. 10% ou frais pro) de la 4�me PAC (�)";


		/** Ensemble des membres du foyer fiscal **/
        tsnet       =   tsn1 + tsn2 + tsn3 + tsn4 + tsn5 + tsn6;
        label tsnet =   "TS et gains de cess. d'op nets (apr�s abat. 10% ou frais pro) au niveau du foyer fiscal" ;
        
        chonet      = _1ap + _1bp + _1cp + _1dp + _1ep + _1fp + tspn1 + tspn2 + tspn3 + tspn4 + tspn5 + tspn6 ; 

        array TSquotient{2} TSquotientA TSquotientB;
        TSquotientA = tsjn1 + tsjn2 + tsjn3 + tsjn4 + tsjn5 + tsjn6  
                    + tspn1 + tspn2 + tspn3 + tspn4 + tspn5 + tspn6 
                    + tsvn1 + tsvn2 
                    + tswn1 + tswn2 
                    + tsxn1 + tsxn2 ; 
        
        TSquotientB = (tsvn1 + tsvn2)/1 
                    + (tswn1 + tswn2)/2 
                    + (tsxn1 + tsxn2)/3 ;

        tsord       =   tskn1 + tskn2 + tskn3 + tskn4 + tskn5 + tskn6 ; 
        label tsord =   "Montant des traitements et salaires ordinaires, i.e. non soumis au quotient (�)" ;



/**************************************************************************************************************************************************************/
/*		d. Revenu net cat�goriel : pensions et retraites																		 		                      */
/**************************************************************************************************************************************************************/

    /*Etape 1 : revenus bruts ordinaires et au quotient*/   
        prb1 = _1as + _1ao ;
        prb2 = _1bs + _1bo ;
        prb3 = _1cs + _1co ;
        prb4 = _1ds + _1do ;
        prb5 = _1es + _1eo ;
        prb6 = _1fs + _1fo ;

        label   prb1    =   "Pensions et retraites brutes du d�clarant" 
                prb2    =   "Pensions et retraites brutes du conjoint"
                prb3    =   "Pensions et retraites brutes de la 1�re PAC"
                prb4    =   "Pensions et retraites brutes de la 2�me PAC"
                prb5    =   "Pensions et retraites brutes de la 3�me PAC"
                prb6    =   "Pensions et retraites brutes de la 4�me PAC" ;

    /*Etape 2 : abattement de 10%, sachant qu'il ne peut pas �tre inf�rieur � pen_abat_min pour chacun des titulaires de pensions, mais lorsque la pension
				est inf�rieure � pen_abat_min, la d�duction est limit�e au montant de la pension*/ 
        adn1 = min(max(&pen_abat_taux.*prb1, &pen_abat_min.), prb1);
        adn2 = min(max(&pen_abat_taux.*prb2, &pen_abat_min.), prb2);
        adn3 = min(max(&pen_abat_taux.*prb3, &pen_abat_min.), prb3);
        adn4 = min(max(&pen_abat_taux.*prb4, &pen_abat_min.), prb4);
        adn5 = min(max(&pen_abat_taux.*prb5, &pen_abat_min.), prb5);
        adn6 = min(max(&pen_abat_taux.*prb6, &pen_abat_min.), prb6);
        
    /*Etape 3 : abattement de 10% : l abattement de 10% ne peut depasser pen_abat_max par foyer*/ 
        if adn1 + adn2 + adn3 + adn4 + adn5 + adn6 > &pen_abat_max. then do; 

	/*Etape 4 : la part de l'abattement de 10% qu'il reste est imput�e sur les autres revenus*/
            reste = &pen_abat_max. - ( adn1*(adn1 <= &pen_abat_min.) + 
                                       adn2*(adn2 <= &pen_abat_min.) +
                                       adn3*(adn3 <= &pen_abat_min.) +
                                       adn4*(adn4 <= &pen_abat_min.) + 
                                       adn5*(adn5 <= &pen_abat_min.) + 
                                       adn6*(adn6 <= &pen_abat_min.));

            label reste = "Diff�rence entre le plafonnement de l'abat. de 10% au niveau du foyer fiscal et la somme
                            des abat. per�us au niveau individuel" ; 

            indicateur= (adn1 > &pen_abat_min.)*1+
                        (adn2 > &pen_abat_min.)*20+
                        (adn3 > &pen_abat_min.)*300+
                        (adn4 > &pen_abat_min.)*4000+
                        (adn5 > &pen_abat_min.)*50000+
                        (adn6 > &pen_abat_min.)*600000;
            label indicateur    = "Num�ro qui indique qui au sein du foyer b�n�ficie de l'abat. de 10%" ; 

	/*Etape 5: somme des pensions auxquelles il faut imputer l'abattement restant de 10%*/

            pensionrestante = prb1*(index(indicateur,'1') ne 0)
                            + prb2*(index(indicateur,'2') ne 0)
                            + prb3*(index(indicateur,'3') ne 0) 
                            + prb4*(index(indicateur,'4') ne 0)
                            + prb5*(index(indicateur,'5') ne 0)
                            + prb6*(index(indicateur,'6') ne 0) ;

            adn1 = (adn1 <= &pen_abat_min.)*adn1 + (adn1 > &pen_abat_min.)*prb1*reste/pensionrestante;
            adn2 = (adn2 <= &pen_abat_min.)*adn2 + (adn2 > &pen_abat_min.)*prb2*reste/pensionrestante;
            adn3 = (adn3 <= &pen_abat_min.)*adn3 + (adn3 > &pen_abat_min.)*prb3*reste/pensionrestante;
            adn4 = (adn4 <= &pen_abat_min.)*adn4 + (adn4 > &pen_abat_min.)*prb4*reste/pensionrestante;
            adn5 = (adn5 <= &pen_abat_min.)*adn5 + (adn5 > &pen_abat_min.)*prb5*reste/pensionrestante;
            adn6 = (adn6 <= &pen_abat_min.)*adn6 + (adn6 > &pen_abat_min.)*prb6*reste/pensionrestante;

            label   adn1    =   "Montant de l'abat. de 10% dont b�n�ficie le d�clarant, apr�s prise en compte du plafon au niveau du foyer fiscal" 
                    adn2    =   "Montant de l'abat. de 10% dont b�n�ficie le conjoint, apr�s prise en compte du plafon au niveau du foyer fiscal"
                    adn3    =   "Montant de l'abat. de 10% dont b�n�ficie la 1�re PAC, apr�s prise en compte du plafon au niveau du foyer fiscal"
                    adn4    =   "Montant de l'abat. de 10% dont b�n�ficie la 2�me PAC, apr�s prise en compte du plafon au niveau du foyer fiscal"
                    adn5    =   "Montant de l'abat. de 10% dont b�n�ficie la 3�me PAC, apr�s prise en compte du plafon au niveau du foyer fiscal"
                    adn6    =   "Montant de l'abat. de 10% dont b�n�ficie la 4�me PAC, apr�s prise en compte du plafon au niveau du foyer fiscal" ;
        end;

        prn1 = round(prb1-adn1);
        prn2 = round(prb2-adn2);
        prn3 = round(prb3-adn3);
        prn4 = round(prb4-adn4);
        prn5 = round(prb5-adn5);
        prn6 = round(prb6-adn6);

        /*R�partition des abattements de 10% entre revenus ordinaires et au quotient*/
        if prb1 ne 0 then do ;
            prkn1 = round((_1as+_1ao)*prn1/prb1);
            prsn1 = 0;
            pron1 = 0;
        end;
        else do;
            prkn1 = 0; 
            prsn1 = 0; 
            pron1 = 0; 
        end;

        /*R�partition des abattements de 10% entre revenus ordinaires et au quotient*/
        if prb2 ne 0 then do ;
            prkn2 = round((_1bs+_1bo)*prn2/prb2);
            prsn2 = 0;
            pron2 = 0;
        end; 
        else do;
            prkn2 = 0; 
            prsn2 = 0; 
            pron2 = 0; 
        end;

        /*R�partition des abattements de 10% entre revenus ordinaires et au quotient*/
        if prb3 ne 0 then do ;
            prkn3 = round((_1cs+_1co)*prn3/prb3);
            prsn3 = 0;
            pron3 = 0;
        end;
        else do;
            prkn3 = 0; 
            prsn3 = 0; 
            pron3 = 0; 
        end;

        /*R�partition des abattements de 10% entre revenus ordinaires et au quotient*/
        if prb4 ne 0 then do ;
            prkn4 = round((_1ds+_1do)*prn4/prb4);
            prsn4 = 0;
            pron4 = 0;
        end;
        else do;
            prkn4 = 0; 
            prsn4 = 0; 
            pron4 = 0; 
        end;

        /*R�partition des abattements de 10% entre revenus ordinaires et au quotient*/ 
        if prb5 ne 0 then do ;
            prkn5 = round((_1es+_1eo)*prn5/prb5);
            prsn5 = 0; 
            pron5 = 0; 
        end;
        else do;
            prkn5 = 0; 
            prsn5 = 0; 
            pron5 = 0; 
        end;

        /*R�partition des abattements de 10% entre revenus ordinaires et au quotient*/
        if prb6 ne 0 then do ;
            prkn6 = round((_1fs+_1fo)*prn6/prb6);
            prsn6 = 0;
            pron6 = 0;
        end;
        else do;
            prkn6 = 0; 
            prsn6 = 0; 
            pron6 = 0; 
        end;

        prn1            =   prkn1 + prsn1 + pron1 ;
        prn2            =   prkn2 + prsn2 + pron2 ;
        prn3            =   prkn3 + prsn3 + pron3 ;
        prn4            =   prkn4 + prsn4 + pron4 ;
        prn5            =   prkn5 + prsn5 + pron5 ;
        prn6            =   prkn6 + prsn6 + pron6 ;
        label   prn1    =   "Pensions et retraites nettes (arp�s abat. des 10%) du d�clarant"; 
        label   prn2    =   "Pensions et retraites nettes (arp�s abat. des 10%) du conjoint"; 
        label   prn3    =   "Pensions et retraites nettes (arp�s abat. des 10%) de la 1�re PAC"; 
        label   prn4    =   "Pensions et retraites nettes (arp�s abat. des 10%) de la 2�me PAC"; 
        label   prn5    =   "Pensions et retraites nettes (arp�s abat. des 10%) de la 3�me PAC"; 
        label   prn6    =   "Pensions et retraites nettes (arp�s abat. des 10%) de la 4�me PAC"; 

 
		/** Ensemble des membres du foyer fiscal **/

        prnet               =   prn1 + prn2 + prn3 + prn4 + prn5 + prn6 ;
        label prnet         =   "Montant des pensions et retraites nettes (arp�s abat. des 10%) au sein du foyer fiscal (�)" ;

        array PRquotient{2} PRquotientA PRquotientB ;

        PRquotientA = prsn1 + prsn2 + prsn3 + prsn4 + prsn5 + prsn6
                    + pron1 + pron2 + pron3 + pron4 + pron5 + pron6 ;

        PRquotientB = 0 ;

        label   PRquotientA =   "Ens. des pensions et retraites au quotient au niveau du foyer fiscal (apr�s r�partition de l'abat.10%), sans soumission
                                des rev. au syst�me du quotient"
                PRquotientB =   "Ens. des pensions et retraites au quotient au niveau du foyer fiscal (apr�s r�partition de l'abat.10%), avec soumission
                                des rev. au syst�me du quotient" ; 

        PRord               =   prkn1+prkn2+prkn3+prkn4+prkn5+prkn6;
        label PRord         =   "Montant des pensions et retraites ordinaires, i.e. non soumises au quotient (�)" ;
        

/*************************************************************************************************************************************************************/
/*		e. Revenu net cat�goriel : rentes viag�res � titre on�reux (RVTO)														 		                     */
/*************************************************************************************************************************************************************/

	/*La part imposable des rentes viag�res d�pend de l��ge du contribuable au moment de l entr�e en jouissance*/
        rv1 = round(_1aw* &rv_m50_abat.);
        rv2 = round(_1bw* &rv_m60_abat.);
        rv3 = round(_1cw* &rv_m70_abat.);
        rv4 = round(_1dw* &rv_p70_abat.);

        rvord       =   rv1+rv2+rv3+rv4;
        label rvord =   "Montant des RVTO ordinaires, i.e. non soumises au quotient, apr�s l'abat. fonction de l'�ge (�)" ;

	/*Calcul direct des rentes au quotient*/ 

	/*Rentes au quotient pond�r�es et non pond�r�es par le quotient*/
        array rvquotient{2} RVquotientA RVquotientB;

        RVquotientA = 0 ;
        RVquotientB = 0;

        label   RVquotientA =   "Ens. des RVTO au quotient au niveau du foyer fiscal (apr�s abat.), sans soumission des rev. au syst�me du quotient"
                RVquotientB =   "Ens. des RVTO au quotient au niveau du foyer fiscal (apr�s abat.), avec soumission des rev. au syst�me du quotient" ; 

        RVnet = RVord + RVquotientA ;


/*************************************************************************************************************************************************************/
/*		f. Revenu net cat�goriel : revenus de capitaux mobiliers (RCM)															 		                     */
/*************************************************************************************************************************************************************/

			/*** Abattement de 40% appliqu� aux dividendes (case Z2DC), titres non cot�s dans PEA ***/

        demibase2dc = round(_2dc*&rcm_abat_taux.);
        demibaserdc = 0;

        demibase2fu = round(_2fu*&rcm_abat_taux.);
        demibaserfu = 0;

        label   demibase2dc = "Montant de l'abat. de 40% sur les dividendes (rev. des actions et parts)"
                demibase2fu = "Montant de l'abat. de 40% sur les dividendes (rev. imposables des titres non c�t�s d�tenus dans le PEA)" ; 


			/*** Abattement de 40% appliqu� � la quote-part de dividendes per�us via des soci�t�s de personnes (case Z2FU)***/

        _2dcnetdemibase = _2dc - demibase2dc; 
        _rdcnetdemibase = 0 ;

        _2funetdemibase = _2fu - demibase2fu;     
        _rfunetdemibase = 0;

        label   _2dcnetdemibase = "Dividendes (rev. des actions et parts) apr�s abat. de 40%"
                _2funetdemibase = "Dividendes (rev. imposables des titres non c�t�s d�tenus dans le PEA) apr�s abat. de 40%" ; 

	/*D�duction des frais sur RCM (pour 2DC et 2TS)*/
	/*NB: Prise en compte des frais venant en d�duction Z2CA au prorata des Z2DC et Z2TS _ PI: les frais de garde ne peuvent pas s imputer sur 2FU 2CH 2GO*/ 
        rcmfrais        =   _2dc + _2ts ;
        label rcmfrais  =   "Somme des RCM �ligibles � la d�duction des frais Z2CA ";

        if rcmfrais ne 0 then do;

            *R�partition des frais entre RCM ordinaires et au quotient ;  
            frais2dc = round(_2ca*_2dc/rcmfrais);
            fraisrdc = 0;
            frais2ts = round(_2ca*_2ts/rcmfrais);
            fraisrts = 0;

            label   frais2dc    =   "Frais d�ductibles pour les RCM au prorata des revenus des actions et parts (2DC) dans l'ens des RCM"
                    frais2ts    =   "Frais d�ductibles pour les RCM au prorata des revenus de valeurs mobili�res et distributions (2TS) dans l'ens de RCM" ; 

	/*RCM �ligibles nets de frais*/
	/*NB: les revenus nets qui suivent peuvent etre negatifs si z2ca > rcmfrais*/

            _2dcnetfrais = max(0, _2dcnetdemibase - frais2dc);       
            _rdcnetfrais = max(0, _rdcnetdemibase - fraisrdc);                                       

            _2tsnet = max(0, _2ts-frais2ts);   
            _rtsnet = 0;                                   
    
            label   _2dcnetfrais    =   "Ens. des rev des actions et parts (2DC), nets des frais"
                    _rdcnetfrais    =   "Ens. des rev des actions et parts (2DC) au quotient, nets des frais"
                    _2tsnet         =   "Ens. des rev de valeurs mobili�res et distributions (2TS), nets des frais" 
                    _rtsnet         =   "Ens. des rev de valeurs mobili�res et distributions (2TS) au quotient, nets des frais" ;

	/*Soldes des frais*/

            soldeCA = -min(0,_2dc-demibase2dc-frais2dc)
                      -min(0,_2ts-frais2ts);

            label   soldeca =   "Soldes des frais non imput�s sur des revenus du capital" ; 

        end;
	/*Cas o� il n�y pas de RCM �ligibles � la d�duction des frais*/  
        else do;
            _2dcnetfrais=0;     
            _rdcnetfrais=0;     

            _2tsnet = 0;          
            _rtsnet = 0;          
            soldeCA = _2ca;
        end;


			/*** Abattements fixes sur RCM ***/

		/** Abattements fixes sur revenus des actions et parts (2DC et rev. imposables des titres non c�t�s d�tenus dans le PEA (2FU) **/
        rcmabattement1      = (_2dcnetfrais + _rdcnetfrais);
        label rcmabattement1 =   "Montant total des RCM �ligibles aux abattements fixes : 2DC si pas de PFL et 2FU"; 

        abattement1       = &rcm_abat_forf_2.*(matn in (1 6)) + &rcm_abat_forf_1.*(matn in (2 3 4));
        label abattement1 = "Valeur des abattements sur les RCM (2DC et 2FU si pas de PFL) selon la situation familiale" ; 

        abattement2dc=0;

	/*Les RCM (2DC et 2FU si pas de PFL) �ligibles aux abattements ne sont pas absorb�s enti�rement par les abattements*/ 
        if rcmabattement1 > abattement1 then do;
	/*Les abattements n�1 ne s�appliquent qu�en l�absence de PFL*/ 
     
	/*R�partition au prorata des abattements entre les RCM �ligibles et calcul du solde de ces abattements*/
                    abattement2dc=round(abattement1*_2dcnetfrais/rcmabattement1);   
                    solde=max(0,abattement1-abattement2dc);
                    abattementrdc=min(solde , round(abattement1*_rdcnetfrais/rcmabattement1));              solde=max(0,solde-abattementrdc);   

                    abattement2fu=min(solde , round(abattement1*_2funetdemibase/rcmabattement1));           solde=max(0,solde-abattement2fu);
                    abattementrfu=min(solde , round(abattement1*_rfunetdemibase/rcmabattement1));           solde=max(0,solde-abattementrfu);   

                    label   abattement2dc   =   "Abat.sur les revenus des actions et parts (2DC) au prorata de leur poids dans l'ens des RCM"
                            abattement2fu   =   "Abat.sur les rev. imposables des titres non c�t�s d�tenus dans le PEA (2FU) 
                                                au prorata de leur poids dans l'ens des RCM" 
                            abattementrdc   =   "Abat.sur les revenus au quotient des actions et parts (2DC) au prorata de leur poids dans l'ens des RCM"
                            abattementrfu   =   "Abat.sur les rev. imposables au quotient des titres non c�t�s d�tenus dans le PEA (2FU) 
                                                au prorata de leur poids dans l'ens des RCM"; 

	/*RCM �ligibles nets des abattements*/
                    _2dcnet=_2dcnetfrais-abattement2dc; 
                    _rdcnet=_rdcnetfrais-abattementrdc; 

                    _2funet=_2funetdemibase-abattement2fu;      
                    _rfunet=_rfunetdemibase-abattementrfu;   

            
            end;
            else do;   
            _2funet=0;      
            _rfunet=0;

        end;

        label   _2dcnet =   "Revenus des actions et parts (2DC) apr�s abat. fixe"
                _2funet =   "Revenus imposables des titres non c�t�s d�tenus dans le PEA (2FU) apr�s abat. fixe" 
                _rdcnet =   "Revenus au quotient des actions et parts (2DC) apr�s abat. fixe"
                _rfunet =   "Revenus imposables au quotient des titres non c�t�s d�tenus dans le PEA (2FU) apr�s abat. fixe" ; 
            
		/** Abattements fixes sur les produits des contrats d'assurance-vie et de capitalisation d'une dur�e d'au moins 6 ou 8 ans (2CH) **/
        rcmabattement2      =   _2ch ;
        label rcmabattement2=   "Montant total des RCM eligibles aux abattements fixes sp�cifiques � l'assurance-vie : 2CH"; 

        abattement2         =   min(rcmabattement2, &av_couple_abat.*(matn in (1 6)) + &av_seul_abat.*(matn in (2 3 4))) ;
        label abattement2   =   "Valeur des abattements fixes sp�cifiques � l'assurance-vie sur les RCM selon la situation familiale";


        if rcmabattement2 > 0 then do;

	/*R�partition au prorata des abattements entre les RCM �ligibles et calcul du solde de ces abattements*/ 
            abattement2ch = round(abattement2*_2ch/rcmabattement2);
            abattementrch = 0;   

            label   abattement2ch   =   "Abat.sur les produits des contrats d'assurance-vie (2CH) au prorata des rev. ordinaires et au quotient" ; 

	/*RCM �ligibles nets des abattements sp�cifiques � l assurance-vie et produits de capitalisation*/ 
            _2chnet = max(_2ch-abattement2ch, 0) ;
            _rchnet = 0 ;

        end;
        else do;

	/*Cas o� la totalit� des RCM �ligibles aux abattements est r�duite � 0 par ces abattements*/ 
            _2chnet = 0;      
            _rchnet = 0;
            abattement2ch = 0;
            abattementrch = 0; 
        end;

        label _2chnet   =   "Produits des contrats d'assurance-vie et de capitalisation (2CH) apr�s abat. fixes sp�cifiques"
              _rchnet   =   "Produits des contrats d'assurance-vie et de capitalisation (2CH), au quotient, apr�s abat. fixes sp�cifiques";


			/*** Majoration des revenus soumis hors de france � un r�gime fiscal privil�gi� (2GO) ***/
 
        _2gonet=round(_2go*&maj_taux.); 
        _rgonet=0; 

        label   _2gonet =   "Rev. des structures soumises hors de France � un r�gime fiscal privil�gi� apr�s majoration de 25%" 
                _rgonet =   "Rev. au quotient des structures soumises hors de France � un r�gime fiscal privil�gi� apr�s majoration de 25%"; 


			/*** Cas des Int�r�ts et autres revenus assimil�s ***/

        _2trnet=_2tr;   
        _rtrnet=0;   

		/** D�duction du reste des frais CA (soldeCA) sur les RCM (2GO et 2TR - autres que 2DC et 2TS) **/        

        rcmfrais2       =   _2funet + _rfunet + _2chnet + _rchnet +
                            _2gonet + _rgonet + _2trnet + _rtrnet ;
        label rcmfrais2 =   "Total des autres RCM �ligibles � la d�duction des frais " ; 

        if soldeca>0 then do;
            if rcmfrais2 > soldeCA then do;
                frais2fu = round(soldeca*_2fu/rcmfrais2);
                fraisrfu = 0;

                frais2ch = round(soldeca*_2ch/rcmfrais2);
                fraisrch = 0;

                frais2go = round(soldeca*_2go/rcmfrais2);
                fraisrgo = 0;

                frais2tr = round(soldeca*_2tr/rcmfrais2);
                fraisrtr = 0;

                _2funet=_2funet-frais2fu;   
                _rfunet=_rfunet-fraisrfu;   

                _2chnet=_2chnet-frais2ch;   
                _rchnet=_rchnet-fraisrch;   
                    
                _2gonet=_2go-frais2go;      
                _rgonet=0;      
            
                _2trnet=_2tr-frais2tr;
                _rtrnet=0;
            end; 
            else do;
                _2funet=0;  _rfunet=0;  
                _2chnet=0;  _rchnet=0;  
                _2gonet=0;  _rgonet=0;  
                _2trnet=0;  _rtrnet=0;
            end;
        end;
        label   _2trnet =   "Int�r�ts et autres revenus assimil�s avant d�duction des frais"
                _rtrnet =   "Int�r�ts et autres revenus, au quotient, assimil�s avant d�duction des frais"  ;

			/*** Imputation du report d�ficitaire ***/

        rcmNetOrd       =   max(0,_2dcnet) + max(0,_2funet) + max(0,_2tsnet) + max(0,_2chnet) + max(0,_2gonet) + max(0,_2trnet) ;


        intNetOrd       =   max(0,_2tsnet) + max(0,_2trnet) ;
        divNetOrd       =   max(0,_2dcnet) + max(0,_2funet) + max(0,_2gonet) ;
        avNetOrd        =   max(0,_2chnet) ;  

        _rdcNet = max(0,_rdcNet) ;
        _rfuNet = max(0,_rfuNet) ;
        _rtsNet = max(0,_rtsNet) ;
        _rchNet = max(0,_rchNet) ;
        _rgoNet = max(0,_rgoNet) ;
        _rtrNet = max(0,_rtrNet) ;
        _rvgNet = 0 ;

        rcmNetQuo  =   _rdcNet + _rfuNet + _rtsNet + _rchNet + _rgoNet + _rtrNet + _rvgNet ;
        intNetQuo       =   _Rtrnet ;
        divNetQuo       =   _Rdcnet + _Rfunet + _Rtsnet + _Rgonet ;
        avNetQuo        =   _Rchnet ;

        rcmNetTot       =   rcmNetOrd + rcmNetQuo ;
        intNetTot       =   intNetOrd + intNetQuo ;
        divNetTot       =   divNetOrd + divNetQuo ;
        report_deficit = _2aa + _2al + _2am + _2an + _2aq + _2ar;

        if rcmNetTot ne 0 then do;

            defRcmOrd = round(report_deficit*rcmNetOrd/rcmNetTot);                       
            defRcmQuo = round(report_deficit - defRcmOrd);                       

            rcmNetOrd = max(0, rcmNetOrd - defRcmOrd) ;

            if rcmNetQuo > 0 then do;
                _rdcNet = max(0, _rdcNet -  _rdcNet*defRcmQuo/rcmNetQuo) ;
                _rfuNet = max(0, _rfuNet -  _rfuNet*defRcmQuo/rcmNetQuo) ;
                _rtsNet = max(0, _rtsNet -  _rtsNet*defRcmQuo/rcmNetQuo) ;
                _rchNet = max(0, _rchNet -  _rchNet*defRcmQuo/rcmNetQuo) ;
                _rgoNet = max(0, _rgoNet -  _rgoNet*defRcmQuo/rcmNetQuo) ;
                _rtrNet = max(0, _rtrNet -  _rtrNet*defRcmQuo/rcmNetQuo) ;
                _rvgNet = max(0, _rvgNet -  _rvgNet*defRcmQuo/rcmNetQuo) ;

                rcmNetQuo =  sum(_rdcNet, _rfuNet, _rtsNet, _rchNet, _rgoNet, _rtrNet, _rvgNet) ;
                intNetQuo       =   _Rtrnet ;
                divNetQuo       =   _Rdcnet + _Rfunet + _Rtsnet + _Rgonet ;
                avNetQuo        =   _Rchnet ;
            end ;

        end;


			/*** Bar�misation des PVM ***/ 

/*La bar�misation des pvm consiste � appliquer un r�gime d'abattements sp�cifiques � une assiette de pvm constitu�e de : 
            - les plus values impos�es � taux proportionnel (24%)
            - l'abattement dont b�n�ficient les dirigeants partant � la retraite
            - les pvm des entrepreneurs taxables � 19%
            - les pv de cession des groupes intra familiaux
            - les pv exon�r�es de cession des jeunes entreprises innovantes*/

        pvm = (_3vg + _3vl)*&switch_pvm. ;
        pvmNetOrd = pvm ;
    
        rcmNet    =  rcmNetOrd + rcmNetQuo ;
        intNet    =  intNetOrd + intNetQuo ;
        divNet    =  divNetOrd + divNetQuo ;
        avNet     =  avNetOrd  + avNetQuo ;
    
        label   rcmNetOrd = "Total des PVM sans les revenus au quotient" ;
    
        label   rcmNetOrd = "Total des RCM sans les revenus au quotient"
                rcmNetQuo = "Total des revenus au quotient issus des RCM" ; 
        
        label   intNetOrd = "Total des int�r�ts sans les revenus au quotient"
                intNetQuo = "Total des int�r�ts au quotient issus des RCM" ; 

        label   divNetOrd = "Total des dividendes sans les revenus au quotient"
                divNetQuo = "Total des dividendes au quotient issus des RCM" ; 
        
        label   avNetOrd  = "Total des produits d'assurance vie impos�s au bar�me sans les revenus au quotient"
                avNetQuo  = "Total des produits d'assurance vie impos�s au bar�me au quotient issus des RCM" ; 


        label   rcmNetOrd = "Total des RCM sans les revenus au quotient"
                rcmNetQuo = "Total des revenus au quotient issus des RCM" ; 

        array RCMnetQuotient{2} RCMnetquotientA RCMnetquotientB ;

        RCMnetQuotientA = rcmNetQuo ;
        RCMnetQuotientB = 0 ;


/*************************************************************************************************************************************************************/
/*		g. Revenu net cat�goriel : revenus fonciers (RF)																		 		                     */
/*************************************************************************************************************************************************************/

    /*On neutralise les revenus fonciers de fa�on asymetrique : seuls les benefices sont major�s de 25%*/
    array RFnetQuotient{2} RFnetQuotientA RFnetQuotientB;
    RFnetQuotientA = 0 ;
    RFnetQuotientB = 0 ;

    if (_4ba) > 0 or _4bb > 0 or _4bc > 0 then do;
        /*Exclut l application du micro-foncier*/
        /*On impute les deficits au prorata sur z4ba zaba zbba zcba zdba zeba zfba et zgba*/

        if (_4ba - _4bb - _4bc)>0 then do;
            /*les deficits anterieurs (bd) viennent apr�s le reste*/
            _4banet = max(0,round(_4ba*1)-round((_4bb+_4bc+_4bd)*_4ba/(_4ba))) ;
            _rbanet = 0 ;

            RFnetOrd = _4banet;

        end;

        else do; /*4bc est imputable sur le revenu global*/
            if (_4ba)>0 then do;
                _4banet=max(0, round(_4ba*1) - round(_4bb*_4ba/(_4ba))) - round(_4bc*_4ba/(_4ba));
                _rbanet=0;

                RFnetOrd = _4banet;

            end;
            else do;
                RFnetOrd=-_4bc;
            end;
        end; 
    end;
        /*NB: le micro-foncier (be) exclut l application de deficits de l annee (4bb et 4bc)(et est incompatible avec z4ba), 
        mais les d�ficits des ann�es ant�rieures peuvent �tre imput�s sur les revenus nets determin�s selon le r�gime micro-foncier*/
    else do;
        RFnetOrd = max(0, round(_4be*0.7-_4bd));
    end;

    rfonet          =   RFnetOrd ;
    label rfonet    =   "Montant des revenus fonciers nets, hors et au quotient (�)" ; 


/*************************************************************************************************************************************************************/
/*		h. Revenu net cat�goriel : b�n�fices agricoles																			 		                     */
/*************************************************************************************************************************************************************/

			/*** Revenus soumis au r�gime du b�n�fice r�el ***/

		/** Adh�rents � un CGA **/

/*D�clarant*/ 
        badeccga            =   _5hc ;
        label badeccga      =   "B�n�fice agricole du d�clarant adh�rent � un CGA avant imputation de l'�ventuel d�ficit agricole" ; 

        badeccganet         =   (_5hc) - _5hf;
        label badeccganet   =   "B�n�fice agricole net du d�clarant adh�rent � un CGA, i.e. apr�s imputation du d�ficit agricole" ;

        /*R�partition du d�ficit existant entre BA ordinaire et BA au quotient*/ 
        if (badeccganet>=0 & badeccga>0) then do;
            badeccgan1  =   _5hc-round(_5hf*_5hc/badeccga);     *revenu ordinaire net;
            badeccgan4  =   0;
           end;
           else do;
            badeccgan1  =   badeccga-_5hf;
            badeccgan4  =   0;
        end;

/*Conjoint*/
        baconjcga           =   _5ic;
        label baconjcga     =   "B�n�fice agricole du conjoint adh�rent � un CGA avant imputation de l'�ventuel d�ficit agricole" ; 


        baconjcganet=(_5ic)-_5if;
        label baconjcganet  =   "B�n�fice agricole net du conjoint adh�rent � un CGA, i.e. apr�s imputation du d�ficit agricole" ;

        /*R�partition du d�ficit existant entre BA ordinaire et BA au quotient*/ 
        if (baconjcganet>=0 & baconjcga>0) then do;
            baconjcgan1 =   _5ic-round(_5if*_5ic/baconjcga);
            baconjcgan4 = 0;
           end;
           else do;
            baconjcgan1 =   baconjcga-_5if;
            baconjcgan4 =   0;
        end;

/*Personne � charge*/
        bapaccga=_5jc;
        label bapaccga      =   "B�n�fice agricole de la personne � charge adh�rente � un CGA avant imputation de l'�ventuel d�ficit agricole" ; 

        bapaccganet=(_5jc)-_5jf;
        label bapaccganet   =   "B�n�fice agricole net de la personne � charge adh�rente � un CGA, i.e. apr�s imputation du d�ficit agricole" ;

        /*R�partition du d�ficit existant entre BA ordinaire et BA au quotient*/
        if (bapaccganet>=0 & bapaccga>0) then do;
            bapaccgan1  =   _5jc-round(_5jf*_5jc/bapaccga);
            bapaccgan4  = 0;
           end;
           else do;
            bapaccgan1  =   bapaccga-_5jf;
            bapaccgan4  =   0;
        end;


		/** Non-adh�rents � un CGA **/

/*D�clarant*/
        badecnoncga         =   _5hi;
        label badecnoncga   =   "B�n�fice agricole du d�clarant non adh�rent � un CGA avant imputation de l'�ventuel d�ficit agricole" ; 


        badecnoncganet      =   (_5hi)-_5hl;
        label badecnoncganet=   "B�n�fice agricole net du d�clarant non adh�rent � un CGA, i.e apr�s imputation du d�ficit agricole" ; 

        /*R�partition du d�ficit existant entre BA ordinaire et BA au quotient*/
        if (badecnoncganet>=0 & badecnoncga>0) then do;
            badecnoncgan1   =   round((_5hi-round(_5hl*_5hi/badecnoncga))*&maj_taux.); /*revenu ordinaire net*/
            badecnoncgan4   =   0;
           end;
           else do;
            badecnoncgan1   =   badecnoncga-_5hl;
            badecnoncgan4   =   0;
        end;

/*Conjoint*/
        baconjnoncga        =   _5ii;
        label baconjnoncga  =   "B�n�fice agricole du conjoint non adh�rent � un CGA avant imputation de l'�ventuel d�ficit agricole" ;         

        baconjnoncganet         =   (_5ii)-_5il;
        label baconjnoncganet   =   "B�n�fice agricole net du conjoint non adh�rent � un CGA, i.e apr�s imputation du d�ficit agricole" ; 

        if (baconjnoncganet>=0 & baconjnoncga>0) then do;
            baconjnoncgan1  =   round((_5ii-round(_5il*_5ii/baconjnoncga))*&maj_taux.); /*revenu ordinaire net*/
            baconjnoncgan4  =   0;
           end;
           else do;
            baconjnoncgan1  =   baconjnoncga-_5il;
            baconjnoncgan4  =   0;
        end;

/*Personne � charge*/
        bapacnoncga         =   _5ji;
        label bapacnoncga   =   "B�n�fice agricole de la personne � charge non adh�rente � un CGA avant imputation de l'�ventuel d�ficit agricole" ;    

        bapacnoncganet      =   (_5ji)-_5jl;
        label bapacnoncganet=   "B�n�fice agricole net de la personne � charge non adh�rente � un CGA, i.e apr�s imputation du d�ficit agricole" ; 

        if (bapacnoncganet> =0 & bapacnoncga>0) then do;
            bapacnoncgan1   =   round((_5ji-round(_5jl*_5ji/bapacnoncga))*&maj_taux.); *revenu ordinaire net;
            bapacnoncgan4   =   0;
           end;
           else do;
            bapacnoncgan1   =   bapacnoncga-_5jl;
            bapacnoncgan4   =   0;
        end;


			/*** Revenus agricoles soumis au forfait ***/

/*NB:  Le revenu agricole au forfait imposable est determin� comme suit : 
  				benefice agricole forfait major� de 1,25 (sauf pour les revenus agricoles des exploitants forestiers) + plus-values � court terme*/

        badecf  = round(_5ho*&maj_taux.) + _5hd+_5hw;
        baconjf = round(_5io*&maj_taux.) + _5id+_5iw;
        bapacf  = round(_5jo*&maj_taux.) + _5jd+_5jw;


			/*** Ensemble des revenus agricoles (tous r�gimes) ***/

        baord           =   badeccgan1 + baconjcgan1 + bapaccgan1 + badecnoncgan1 + baconjnoncgan1 + bapacnoncgan1
                          + badecf + baconjf + bapacf ;
        label baord     =   "Montant total des b�n�fices agricoles ordinaires d�clar�s au niveau du foyer fiscal (�)" ; 

        baquot4         =   badeccgan4 + baconjcgan4 + bapaccgan4 + badecnoncgan4 + baconjnoncgan4 + bapacnoncgan4  ;
        label baquot4   =   "Montant total des b�n�fices agricoles soumis au quotient d�clar�s au niveau du foyer fiscal (�)" ; 

        /*Imputation des d�ficits ant�rieurs sur les BA dans le "cas g�n�ral"*/ 
        deficit     =   _5qf+_5qg+_5qn+_5qo+_5qp+_5qq;
        if baord>0 then do;
            resteba =   max(0,deficit-baord);
            baord   =   max(0,(baord-deficit));
           end;
           else do 
            resteba =   deficit;
            baord   =   baord;
        end;

		/*Imputation des d�ficits ant�rieurs sur le reste des BA sur les revenus au quotient en imputant prioritairement sur le quotient 2, puis 3, puis 4*/          
   
        baquot4     =   max(0,(baquot4-resteba));

        array baquotient{2} baquotienta baquotientb;

        baquotienta = baquot4;
        baquotientb = baquot4/4;


        BAnet = BAord + BAquotientA ;

/*************************************************************************************************************************************************************/
/*		i. Revenu net cat�goriel : b�n�fices industriels et commerciaux															 		                     */
/*************************************************************************************************************************************************************/

			/*** [BIC professionnel] : r�gime de l auto-entrepreneur ***/

        /*R�sultat apr�s abattement forfaitaire de 50% ou 71% - revenus ordinaire et au quotient*/ 
        tatax=round((_5ta-(&auto_abat_min.<>(_5ta* &auto_vente_abat.)))<>0); 
        uatax=round((_5ua-(&auto_abat_min.<>(_5ua* &auto_vente_abat.)))<>0); 
        vatax=round((_5va-(&auto_abat_min.<>(_5va* &auto_vente_abat.)))<>0); 
        tbtax=round((_5tb-(&auto_abat_min.<>(_5tb* &auto_service_abat.)))<>0); 
        ubtax=round((_5ub-(&auto_abat_min.<>(_5ub* &auto_service_abat.)))<>0); 
        vbtax=round((_5vb-(&auto_abat_min.<>(_5vb* &auto_service_abat.)))<>0);
 
        bicpae = tatax+uatax+vatax+tbtax+ubtax+vbtax;
        label bicpae    =   "Montant total des BIC soumis au r�gime de l'autoentrepreneur, apr�s abattement forfaitaire" ; 


			/*** [BIC professionnel] : r�gime micro ***/

        kotax=round((_5ko-(&auto_abat_min.<>(min(_5ko,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0); 
        lotax=round((_5lo-(&auto_abat_min.<>(min(_5lo,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0); 
        motax=round((_5mo-(&auto_abat_min.<>(min(_5mo,&auto_ca_vente_plaf.)* &auto_vente_abat.)))<>0); 
        kptax=round((_5kp-(&auto_abat_min.<>(min(_5kp,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0); 
        lptax=round((_5lp-(&auto_abat_min.<>(min(_5lp,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0); 
        mptax=round((_5mp-(&auto_abat_min.<>(min(_5mp,&auto_ca_service_plaf.)* &auto_service_abat.)))<>0);
 
        bicpmicro = kotax + lotax + motax + kptax + lptax + mptax + _5kx + _5lx + _5mx - _5kj - _5lj - _5mj;
        *NB: les moins values _5kj - _5lj - _5mj s imputent sur le rev. global;
        label bicpmicro =   "Montant total des BIC soumis au r�gime de la micro-entreprise, apr�s abattement forfaitaire" ; 


			/*** [BIC professionnel] : r�gime du b�n�fice r�el ***/

		/** Non-adh�rent CGA **/
        bicpnoncga= round((_5ki-_5kl)*((_5ki-_5kl>0)*&maj_taux. + (_5ki-_5kl<=0))) + 
                    round((_5li-_5ll)*((_5li-_5ll>0)*&maj_taux. + (_5li-_5ll<=0))) +
                    round((_5mi-_5ml)*((_5mi-_5ml>0)*&maj_taux. + (_5mi-_5ml<=0))) +
                    round((_5ka-_5qj)*((_5ka-_5qj>0)*&maj_taux. + (_5ka-_5qj<=0))) + 
                    round((_5la-_5rj)*((_5la-_5rj>0)*&maj_taux. + (_5la-_5rj<=0))) + 
                    round((_5ma-_5sj)*((_5ma-_5sj>0)*&maj_taux. + (_5ma-_5sj<=0))) ;

/*NB: les deficits peuvent s imputer sur le revenu global, les variables supprim�es proviennent de la combinaison des r�gimes normaux et simplifi�s*/
        label bicpnoncga    =   "Montant total des BIC soumis au r�gime du b�n�fice r�el et non adh�rent au CGA, apr�s abattement forfaitaire" ; 

		/** Adh�rent CGA **/
        /*D�clarant*/
        /* (1) Le deficit ne s impute pas aux plus-values (mais au revenu global)*/
        bicpcgapvdec=_5ke; 
        /* (2) Cas general - deficit*/
        bicpcgadec=_5kc-_5kf + _5ha - _5qa; 

        /*Conjoint*/
        bicpcgapvconj=_5le; 
        bicpcgaconj=_5lc-_5lf + _5ia - _5ra; 

        /*Personne � charge*/
        bicpcgapvpac=_5me;
        bicpcgapac=_5mc-_5mf + _5ja - _5sa; 


			/*** [BIC professionnel] : Tous r�gimes confondus ***/

        bicpnet = bicpmicro+bicpnoncga+bicpcgadec+bicpcgaconj+bicpcgapac;
        label bicpnet   =   "Montant total des BIC professionnels tous r�gimes confondus, apr�s abattement forfaitaire" ; 


			/*** [BIC non professionnel - locations meubl�es] ***/

        /*R�gime micro*/ 
        NDtax=round((_5nd-(&auto_abat_min.<>(_5nd* &auto_service_abat.)))<>0); 
        ODtax=round((_5od-(&auto_abat_min.<>(_5od* &auto_service_abat.)))<>0); 
        PDtax=round((_5pd-(&auto_abat_min.<>(_5pd* &auto_service_abat.)))<>0); 
        NGtax=round((_5ng-(&auto_abat_min.<>(_5ng* &auto_vente_abat.)))<>0); 
        OGtax=round((_5og-(&auto_abat_min.<>(_5og* &auto_vente_abat.)))<>0); 
        PGtax=round((_5pg-(&auto_abat_min.<>(_5pg* &auto_vente_abat.)))<>0); 

        NJtax=round((_5nj-(&auto_abat_min.<>(_5nj* &auto_vente_abat.)))<>0); 
        OJtax=round((_5oj-(&auto_abat_min.<>(_5oj* &auto_vente_abat.)))<>0); 
        PJtax=round((_5pj-(&auto_abat_min.<>(_5pj* &auto_vente_abat.)))<>0); 

        BICNPrevlocmicro = ndtax + odtax + pdtax + ngtax + ogtax + pgtax + njtax + ojtax + pjtax ; 
        /*R�gime du b�n�fice r�el, avec et sans CGA*/ 
        BICNPrevlocCGA = _5na + _5oa + _5pa - _5ny - _5oy - _5py + _5nm + _5om + _5pm ;  
        BICNPrevlocnonCGA = round((_5nk-_5nz)*((_5nk-_5nz>0)*&maj_taux. + (_5nk-_5nz<=0))) +
                            round((_5ok-_5oz)*((_5ok-_5oz>0)*&maj_taux. + (_5ok-_5oz<=0))) +
                            round((_5pk-_5pz)*((_5pk-_5pz>0)*&maj_taux. + (_5pk-_5pz<=0))) ;


        BICNPrevloc = max(BICNPrevlocmicro + BICNPrevlocCGA + BICNPrevlocnonCGA  - (_5ga + _5gb + _5gc + _5gd + _5ge + _5gf + _5gg + _5gh + _5gi + _5gj),0);


			/*** [BIC non professionnel] : r�gime micro ***/

        NOtax=round((_5NO-(&auto_abat_min.<>(_5NO* &auto_vente_abat.)))<>0);  
        OOtax=round((_5OO-(&auto_abat_min.<>(_5OO* &auto_vente_abat.)))<>0); 
        POtax=round((_5PO-(&auto_abat_min.<>(_5PO* &auto_vente_abat.)))<>0); 
        NPtax=round((_5NP-(&auto_abat_min.<>(_5NP* &auto_service_abat.)))<>0); 
        OPtax=round((_5OP-(&auto_abat_min.<>(_5OP* &auto_service_abat.)))<>0); 
        PPtax=round((_5PP-(&auto_abat_min.<>(_5PP* &auto_service_abat.)))<>0);

        BICNPmicro=NOtax+OOtax+POtax+NPtax+OPtax+PPtax+_5NX+_5OX+_5PX-_5IU;
        /*NB: les moins values IU s imputent sur le revenu global*/
        label BICNPmicro    =   "Montant total des BICNP soumis au r�gime micro, apr�s abattement forfaitaire" ; 


			/*** [BIC non professionnel] : r�gime du b�n�fice r�el ***/

		/** Non-adh�rent CGA **/ 
        BICNPnonCGA =   round((_5NI-_5NL)*((_5NI-_5NL>0)*&maj_taux. + (_5NI-_5NL<=0))) + 
                        round((_5OI-_5OL)*((_5OI-_5OL>0)*&maj_taux. + (_5OI-_5OL<=0))) +
                        round((_5PI-_5PL)*((_5PI-_5PL>0)*&maj_taux. + (_5PI-_5PL<=0))) ; 
        label BICNPnonCGA   =   "Montant total des BICNP soumis au r�gime du b�n�fice r��l et n.a. � un CGA, apr�s abattement forfaitaire" ; 


		/** Adh�rent CGA **/ 
		/*D�clarant*/
        /* (1) Le deficit ne s impute pas aux plus values (mais au revenu global)*/
        BICNPCGAPVdec=_5NE;
        /* (2) Cas general - deficit*/
        BICNPCGAdec=_5NC-_5NF; 

        /*Conjoint*/
        BICNPCGAPVconj=_5OE; 
        BICNPCGAconj=_5OC-_5OF; 

        /*Personne � charge*/
        BICNPCGAPVpac=_5PE; 
        BICNPCGApac=_5PC-_5PF; 


			/*** [BIC non professionnel] : Tous r�gimes confondus ***/

        BICNPnet=BICNPmicro+BICNPnonCGA+BICNPCGAdec+BICNPCGAconj+BICNPCGApac+BICNPrevloc; 
        BICNPnet=max(0,BICNPnet);
        label bicnpnet  =   "Montant total des BICNP tous r�gimes confondus, apr�s abattement forfaitaire" ; 

/*NB : les d�ficits NE peuvent PAS s imputer sur le revevenu global, mais peuvent s imputer sur les BICNP des autres personnes du foyer (cf. sp�cifications)*/

        /*Imputation des d�ficits industriels et commerciaux non professionnels des ann�es ant�rieures non encore d�duits*/
        BICNPdeficitAnterieur=_5RN+_5RO+_5RP+_5RQ+_5RR+_5RW + _5ga + _5gb + _5gc + _5gd + _5ge + _5gf + _5gg + _5gh + _5gi;
        if BICNPnet>0 then BICNPnet=max(BICNPnet-BICNPdeficitAnterieur,0);


			/*** [BIC professionnel ET non professionel] : Tous r�gimes confondus ***/

        BICnet=BICPnet+BICNPnet;
        label BICnet    =   "Montant total des BIC tous r�gimes confondus, apr�s abattement forfaitaire" ; 


/*************************************************************************************************************************************************************/
/*		j. Revenu net cat�goriel : b�n�fices non commerciaux (BNC)																 		                     */
/*************************************************************************************************************************************************************/

			/*** [BNC professionnel] : r�gime de l auto-entrepreneur ***/

        TEtax=round((_5TE-(&auto_abat_min.<>(_5TE* &auto_nc_abat.)))<>0);
        UEtax=round((_5UE-(&auto_abat_min.<>(_5UE* &auto_nc_abat.)))<>0);
        VEtax=round((_5VE-(&auto_abat_min.<>(_5VE* &auto_nc_abat.)))<>0);

        BNCPAE = TEtax+UEtax+VEtax;
        label BNCPAE    =   "Montant total des BNCP au r�gime de l'auto-entrepreneur, apr�s abattement forfaitaire" ; 

			/*** [BNC professionnel] : r�gime micro ***/

        HQtax=round((_5HQ-(&auto_abat_min.<>(_5HQ* &auto_nc_abat.)))<>0);
        IQtax=round((_5IQ-(&auto_abat_min.<>(_5IQ* &auto_nc_abat.)))<>0);
        JQtax=round((_5JQ-(&auto_abat_min.<>(_5JQ* &auto_nc_abat.)))<>0);

        BNCPmicro=HQtax+IQtax+JQtax+_5HV+_5IV+_5JV-_5KZ -_5LZ - _5MZ ;
        /*NB: les moins values KZ s imputent sur le rev. global*/
        label BNCPmicro =   "Montant total des BNCP au r�gime micro, apr�s abattement forfaitaire" ; 


			/*** [BNC professionnel] : r�gime du b�n�fice r�el ***/

		/** Non-adh�rent CGA **/ 
        BNCPnonCGA  =   round((_5QI-_5QK)*( (_5QI-_5QK>=0)*&maj_taux. + (_5QI-_5QK<0) )  ) + 
                        round((_5RI-_5RK)*( (_5RI-_5RK>=0)*&maj_taux. + (_5RI-_5RK<0) )  ) +
                        round((_5SI-_5SK)*( (_5SI-_5SK>=0)*&maj_taux. + (_5SI-_5SK<0) )  ) ;
        /*NB: les d�ficits peuvent s imputer sur le rev. global*/
        label BNCPnonCGA    =   "Montant total des BNCP au r�gime r��l et n.a. � un CGA, apr�s abattement forfaitaire" ; 


		/** Adh�rent CGA **/ 
		/*D�clarant*/
        /*(1) Le deficit ne s impute pas aux pv# (mais au rev. global)*/
        BNCPCGAPVdec=_5QD;
        /*(2) Cas general - deficit*/
        BNCPCGAdec=_5QC-_5QE;

		/*Conjoint*/
        BNCPCGAPVconj=_5RD;
        BNCPCGAconj=_5RC-_5RE;

		/*Personne � charge*/
        BNCPCGAPVpac=_5SD;
        BNCPCGApac=_5SC-_5SE;

        BNCPCGA = BNCPCGAdec + BNCPCGAconj + BNCPCGApac ;
        label BNCPCGA    =   "Montant total des BNCP au r�gime r��l et adh�rents � un CGA" ; 

			/*** [BNC professionnel] : Tous r�gimes confondus ***/
        BNCPnet= BNCPmicro + BNCPnonCGA + BNCPCGA ; /*BNC Auto-entrepreneur non soumis au bar�me*/
        label BNCPnet   =   "Montant total des BNCP tous r�gimes confondus, apr�s abattement forfaitaire" ; 


			/*** [BNC non professionnel] : r�gime d�claratif sp�cial ***/

        KUtax=round((_5KU-(&auto_abat_min.<>(min(_5KU,&auto_ca_service_plaf.)* &auto_nc_abat.)))<>0);
        LUtax=round((_5LU-(&auto_abat_min.<>(min(_5LU,&auto_ca_service_plaf.)* &auto_nc_abat.)))<>0);
        MUtax=round((_5MU-(&auto_abat_min.<>(min(_5MU,&auto_ca_service_plaf.)* &auto_nc_abat.)))<>0);

        BNCNPspecial=KUtax+LUtax+MUtax+max(_5KY+_5LY+_5MY-_5JU,0);
        /*NB: les moins values � CT (JU) s imputent seulement sur les PV � CT*/
        label BNCNPspecial  =   "Montant total des BNCNP soumis au r�gime sp�cial, apr�s abattement forfaitaire" ; 


			/*** [BNC non professionnel] : r�gime de la d�claration contr�l�e ***/

        BNCNPcga = _5jg  + _5rf  + _5sf - _5jj - _5rg - _5sg;
        BNCNPcontrolee=BNCNPcga+round((_5SN-_5SP)*((_5SN-_5SP>=0)*&maj_taux. + (_5SN-_5SP<0))) +  
                        round((_5NS-_5NU)*( (_5NS-_5NU>=0)*&maj_taux. + (_5NS-_5NU<0) )  ) + 
                        round((_5OS-_5OU)*( (_5OS-_5OU>=0)*&maj_taux. + (_5OS-_5OU<0) )  )  ;
        /*NB: les d�ficits SP et SR NE peuvent PAS s imputer sur le rev. global*/
        label BNCNPcontrolee    =   "Montant total des BNCNP soumis au r�gime de la d�claration contr�l�e, apr�s abattement forfaitaire" ; 


			/*** [BNC non professionnel] : Tous r�gimes confondus ***/

        _5SR=_5HT+_5IT+_5JT+_5KT+_5LT+_5MT;
        BNCNPnet=max(BNCNPspecial+BNCNPcontrolee -_5SR,0);
        /*NB : les d�ficits SP et SR NE peuvent PAS s imputer sur le rev. global mais peuvent s imputer aux revenus d�clar�s au r�gime d�claratif sp�cial*/
        label BNCNPnet  =   "Montant total des BNCNP tous r�gimes confondus, apr�s abattement forfaitaire" ; 

			/*** [BNC professionnel ET non professionnel] : Tous r�gimes confondus ***/
        BNCnet=BNCPnet+BNCNPnet;
        label BNCnet    =   "Montant total des BNC tous r�gimes confondus, apr�s abattement forfaitaire" ; 


/*************************************************************************************************************************************************************/
/*		k. Revenu brut global : revenu global - deficits globaux ant�rieurs imput�s												 		                     */
/*************************************************************************************************************************************************************/

			/*** Ensemble des revenus au bar�me impos�s au quotient ***/ 

        array Rquotient{2} RquotientA RquotientB;
        do iter=1 to 2;
            Rquotient{iter} = TSquotient{iter} + PRquotient{iter} + Rvquotient{iter} + RCMnetquotient{iter} + RFnetquotient{iter} +  BAquotient{iter};
        end;

			/*** Revenu brut global hors BA (avec ou sans quotient) ***/  

        array RGX{2} RGXa RGXb;
        /*NB: RGXa=sans revenu quotient, RGXb=avec revenu au quotient/coefficient*/
        
        RGXa = TSord + PRord + RVord + RCMnetOrd + RFOnet + BICnet + BNCnet + pvmNetOrd + _6GH;
        RGXb = TSord + PRord + RVord + RCMnetOrd + RFOnet + BICnet + BNCnet + pvmNetOrd + _6GH + (RquotientB - BAquotientB) ; 


			/*** Revenu brut global avec BA (avec ou sans quotient) � imputation des d�ficits agricoles sous condition de plafond du revenu brut global ***/
 
        array RG{2} RGa RGb;
        if RGXa>&ba_rev_plaf. AND BAord<0 then do;
            RGa=RGXa;
            RGb=RGXb;
           end;
           else do;
            RGa = RGXa + BAord;
            RGb = RGXb + BAord + BAquotientB;
        end;
        /*NB: Les d�ficits agricoles (Z5HF IF JF HL IL JL) ne sont d�ductibles du revenu global seulement si le total des autres revenus nets 
		  (ie. hors BA) <= ba_rev_plaf (53 360 �)*/
        label RGa   =   "Revenu brut global hors quotient"
              RGb   =   "Revenu brut global y compris revenus au quotient"; 


			/*** Imputation des d�ficits ant�rieurs ***/
 
        _6Y = _6FA + _6FB + _6FC + _6FD + _6FE + _6FL ;
    
        array RBGp{2} RBGpA RBGpB;
        /*NB : la variable RBG existe d�j� dans la base*/
        do iter=1 to 2;
            RBGp{iter}=round((RG{iter}-_6Y)<>0);
        end;

        do iter=1 to 2;
            RBGp{iter}=max(0,RBGp{iter}); /*CNBCONR non disponible dans ERFS : indicateur non r�sident*/ 
        end;

        label RBGpA   =   "Revenu brut global hors quotient apr�s imputation des d�ficits ant�rieurs"
              RBGpB   =   "Revenu brut global y compris revenus au quotient apr�s imputation des d�ficits ant�rieurs"; 


/*************************************************************************************************************************************************************/
/*		l. Revenu brut global : revenu brut global - charges � d�duire															 		                     */
/*************************************************************************************************************************************************************/

			/*** Charges d�ductibles de l imp�t sur le revenu ***/ 

		/** CSG d�ductible **/
 
         	/*CSG sur les revenus du patrimoine et les produits de placement*/
             CSGpat         =   _6DE/&csg_pat_ded_def. * &csg_pat_ded.;
             CSGplac        =   round(_2BH*&csg_pla_ded.);  
             DEDZ           =   CSGpat + CSGplac;
             label  CSGpat  =   "CSG d�ductible sur les rev. du patrimoine"
                    CSGplac =   "CSG d�ductible sur les produits de placement"
                    DEDZ    =   "Montant des d�ductions li�s � la CSG d�duc. sur les rev. du patrimoine et les produits de placement" ;

		/** D�duction des frais d accueil **/ 
            DEDM            =   min(_6EU,&age_frais_max.*_6EV);
            label   DEDM    =   "Montant des d�ductions des frais d'acceuil" ; 

		/** D�ductions diverses **/ 
            DEDR=_6DD;

		/** D�duction des pensions alimentaires **/  
            NBPAEMAJ=((_6GI>0)+(_6GJ>0)+(_6GK>0)+(_6GL>0));
            NBPAAUT=(_6GP>0);
   
            %put  &maj_taux.  &pen_alim_max. ;
           DEDK= round(
            sum(
                  &maj_taux.*_6GP,
                             min(&maj_taux.*_6GI, &pen_alim_max.),
                             min(&maj_taux.*_6GJ, &pen_alim_max.),
                             min(&maj_taux.*_6GK, &pen_alim_max.),
                             min(&maj_taux.*_6GL, &pen_alim_max.)
                              )
                       +_6GU
                       +sum(
                             min(_6EL,&pen_alim_max.),   
                             min(_6EM,&pen_alim_max.),
                             min(_6EN,&pen_alim_max.),
                             min(_6EQ,&pen_alim_max.)
                              )
                        );
                              

            if _6QW=0 then do;
                plafondV=_6ps;
                plafondC=_6pt;
                plafondP=_6pu;
               end;
               else do;
                plafondV=4*(_6ps);
                plafondC=4*(_6pt);
                plafondP=4*(_6pu);
            end;

		/** D�duction PERP **/
            dedPERP=0;
            if _6QR=0 then do;
                dedPerP=min(_6RS,plafondV)+_6SS + min(_6RT,plafondC)+_6ST + min(_6RU,plafondP)+_6SU;
               end;
               else do;
                if _6RS>plafondV & (_6RT+_6ST)<plafondC then do;
                    dedPerP=min(_6RS,plafondV+plafondC-_6RT-_6ST)+_6SS + min(_6RT,plafondC)+_6ST + min(_6RU,plafondP)+_6SU;
                   end;
                   else if _6RT>plafondC & (_6RS+_6SS)<plafondV then do;
                   dedPERP=min(_6RS,plafondV)+_6SS + min(_6RT,plafondV+plafondC-_6RS-_6SS)+_6ST + min(_6RU,plafondP)+_6SU;
                   end;
            end;
            
            dedPERP         =   _6RS+_6RT+_6SS+_6ST+_6RU+_6SU;
            label   dedPERP =   "Montant des d�ductions PERP" ; 


		/** D�penses de grosses r�parations des nus propri�taires **/ 
            dedGROREP = min(_6cb+_6hj+_6hk + _6hl, &gro_rep_plaf.) ;

		/** Ensemble des charges d�ductibles **/
            DEDP            =   DEDK + DEDM + DEDR + DEDZ + dedPERP + dedGROREP ;
            label   DEDP    =   "Montant de l'ensemble des charges d�ductibles de l'IR" ; 


			/*** Calcul du revenu net global ***/ 

            array RBGD{2} RBGDa RBGDb;
            do iter=1 to 2;
                RBGD{iter}=(RBGp{iter}-DEDP)<>0;
            end;

            array RNGp{2} RNGpA RNGpB;
            do iter=1 to 2;
                RNGp{iter}=(RBGp{iter}-DEDP)<>0;
            end;
        label RNGpA   =   "Revenu net global hors quotient"
              RNGpB   =   "Revenu net global y compris revenus au quotient"; 

        Charges_imputees=RBGpA-RNGpA-DEDZ;/*hors d�duction de la CSG d�ductible*/


/*************************************************************************************************************************************************************/
/*		m. Revenu brut global imposable : revenu net global - abattements sp�ciaux												 		                     */
/*************************************************************************************************************************************************************/

			/*** Abattement pour les personnes �g�es et invalides ***/ 
        array RNG1{2} RNG1a RNG1b;
            do iter=1 to 2;
                if      RNGp{iter} < &abat_spe_age_plaf_1.                               then RNG1{iter}=(RNGp{iter}-&abat_spe_age_mont_1.*ABTINV)<>0;
                else if &abat_spe_age_plaf_1. <= RNGp{iter} <= &abat_spe_age_plaf_2.     then RNG1{iter}=(RNGp{iter}-&abat_spe_age_mont_2.*ABTINV)<>0;
                else    RNG1{iter} = RNGp{iter};
            end;
			/*** Abattement pour enfant � charge mari� ***/ 
        array RIPO{2} RIPOA RIPOB;
        do iter=1 to 2;
            RIPO{iter} = (RNG1{iter} - N*&abat_spe_enf_marie.) <> 0;
        end;

        Abattements_speciaux=RNGpA-RIPOA;

			/*** Revenu net global imposable ***/

        do iter=1 to 2;
            RIPO{iter}=round(RIPO{iter});
        end;
        
        do iter=1 to 2;
            RICALC{iter}=RIPO{iter};
        end;
        label RICALC1   =   "Revenu net global imposable hors quotient"
              RICALC2   =   "Revenu net global imposable y compris revenus au quotient"; 


/*************************************************************************************************************************************************************/
/*		n. Calcul des revenus cat�goriels																						 		                     */
/*************************************************************************************************************************************************************/
              
        denom =  max(RVord + RCMnetord + RFOnet - DEDZ,0)+ max(TSord,0) + max(PRord,0) + max(BICnet,0) + max(BNCnet,0) + max(BAord,0) ;
        part_sal = max(TSord,0) /max(denom,1);
        part_pr  = max(PRord,0) /max(denom,1);
        part_cap = max(RVord + RCMnetord + RFOnet - DEDZ,0)/max(denom,1);
        part_bic = max(BICnet,0)/max(denom,1);
        part_bnc = max(BNCnet,0)/max(denom,1);
        part_ba  = max(BAord,0) /max(denom,1);




/*************************************************************************************************************************************************************/
/*				6 - Calcul du montant d'impot sur le revenu pay� au niveau du foyer fiscal 							 									 */ 
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/*		a. Calcul du nombre de parts au sein du foyer fiscal																		 		                 */
/*************************************************************************************************************************************************************/

			/*** Calculs de majorations du nombre de parts pour enfants � charge ***/

		/** Majoration pour enfant � charge : cas g�n�ral **/
        majoEnf =   0.5*min(2,F+R+J)+               /*0.5 pour les 2 premiers enfants*/
                    0.5*2*max(0,F+R+J-2)+           /*1 part � partir du 3e enfants*/
                    0.5/2*(F+R+J=0)*min(2,H)+       /*0.25 part pour les 2 premiers enfants en garde altern�e*/
                    0.5/2*2*(F+R+J=0)*max(0,H-2)+   /*0.5 part � partir du 3e enfants en garde altern�e*/
                    0.5/2*(F+R+J=1)*min(1,H)+
                    0.5/2*2*(F+R+J=1)*max(0,H-1)+
                    0.5/2*2*(F+R+J>=2)*H;

		/** Majoration pour enfant handicap� � charge **/
        majoEnfHandi=0.5*(G+R)+0.5/2*nI;

        label   majoEnf         =   "Majoration du nbre de part pour enf. � charge ds le cas g�n�ral" 
                majoEnfHandi    =   "Majoration du nbre de part pour enf. handicap� � charge"; 

		/** Mari�s et pacs�s **/
        if matn in (1 6) then do;
            part    =   2 + majoEnf + majoEnfHandi +
                        0.5*(zPn+zFn) +
                        0.5*(zPn=0 and zFn=0 and (zWn=1 or zSn=1));

            avQF    =   &plaf_qf_1.*2*(part-2) ;

            cplmtQF =   &plaf_qf_4.*(zPn+zFn)+
                        &plaf_qf_4.*((zPn=0)*(zFn=0)*(zWn=1)*(zZn=1) or (zSn=1))+
                        &plaf_qf_4.*(G+R+nI/2);
        end;

		/** C�libataires, divorc�s et s�par�s **/
        if matn in (2 3) then do;

            part    =   1 + majoEnf + majoEnfHandi+
                        0.5*(F+R+J+H=0)*(zPn=1 or (zNn=0)*(zEn=1 or zLn=1) or zWn=1) +
                        0.5*(F+R+J+H>=1)*(zPn=1)+
                        0.5*(F+R+J>=1)*(zTn=1)+
                        0.5/2*(F+R+J=0)*(zTn=1)*min(2,H);

            avQF    =   &plaf_qf_1.*2*(part-1)
                      - &plaf_qf_1.*(min(1,(F+R+J+H=0)*(zNn=0)*(zLn=1 or zEn=1)*(zGn=0)*(zPn=0)*(zWn=0) + (zTn=1)*((F+J>=1) + (F+J+R=0)*min(2,H)/2)))
                      + &plaf_qf_3.*(F+R+J+H=0)*(zNn=0)*(zGn=0)*(zPn=0)*(zWn=0)*(zLn=1)
                      + &plaf_qf_5.*(F+R+J+H=0)*(zNn=0)*(zGn=0)*(zPn=0)*(zWn=0)*(zLn=0)*(zEn=1)
                      + (&plaf_qf_2.-&plaf_qf_1.)*(F+J>=1)*(zTn=1)
                      + (&plaf_qf_2.-&plaf_qf_1.)/2*(F+J+R=0)*(zTn=1)*min(2,H) ;

                      

            cplmtQF =   &plaf_qf_4.*(F+R+J+H=0)*((zGn=1 or zWn=1)*(zPn=0) )+
                        &plaf_qf_4.*(zPn+zFn+G+R+nI/2);
        end;

		/** Veufs **/
        if matn in (4) then do;

		/** Veufs assimil�s � un couple **/
	/* Conjoint mort dans l annee */
            if zZn=1 or (zZn=0 and (F+R+J+H)>=1) then do;
                part    =   2 + majoEnf + majoEnfHandi +
                            0.5*(F+R+J+H>0)*(zPn+zFn) +
                            0.5*(F+R+J+H>0)*(zPn=0 and zFn=0 and (zWn=1 or zSn=1)) 
                            + 0.5*(F+R+J+H=0)*(zPn=1 or zFn=1 or zWn=1 or zGn=1)*max(1,zPn+zFn) ; /*note 6*/

                avQF    = &plaf_qf_1.*2*(part-2) ;

                cplmtQF =   &plaf_qf_4.*(F+R+J+H=0)*((zGn=1 or zWn=1)*(zPn=0) )+
                            &plaf_qf_4.*(zPn+zFn+G+R+nI/2);

            end;

	/* Pour enfant � charge */
            else if(zZn=0 and (F+R+J+H)>=1) then do;
                part    =   2 + majoEnf + majoEnfHandi +
                            0.5*(F+R+J+H>0)*(zPn+zFn) +
                            + 0.5*(F+R+J+H=0)*(zPn=1 or zFn=1 or zWn=1 or zGn=1)*max(1,zPn+zFn) ; /*note 6*/

                avQF    =   &plaf_qf_1.*2*(part-1) ;

                cplmtQF =  &plaf_qf_4.*(zPn+zFn)+
                           &plaf_qf_4.*(G+R+nI/2)
                         + &plaf_qf_6.;

            end;

		/** Veufs assimil�s � un c�libataire **/
            else do;
                part=   1 + majoEnf + majoEnfHandi +
                        0.5*(F+R+J+H=0)*(zPn=1 or (zNn=0)*(zEn=1 or zLn=1) or zWn=1 or zGn=1) +
                        0.5*(F+R+J+H>=1)*(zPn=1)+
                        0.5*(F+R+J>=1)*(zTn=1)+
                        0.5/2*(F+R+J=0)*(zTn=1)*min(2,H);

                avQF  = &plaf_qf_1.*2*(part-1)
                      - &plaf_qf_1.*(min(1,(F+R+J+H=0)*(zNn=0)*(zLn=1 or zEn=1)*(zGn=0)*(zPn=0)*(zWn=0) + (zTn=1)*((F+J>=1) + (F+J=0)*min(2,H)/2)))
                      + &plaf_qf_3.*(F+R+J+H=0)*(zNn=0)*(zGn=0)*(zPn=0)*(zWn=0)*(zLn=1)
                      + &plaf_qf_5.*(F+R+J+H=0)*(zNn=0)*(zGn=0)*(zPn=0)*(zWn=0)*(zLn=0)*(zEn=1)
                      + (&plaf_qf_2.-&plaf_qf_1.)*(F+J>=1)*(zTn=1)
                      + (&plaf_qf_2.-&plaf_qf_1.)/2*(F+J=0)*(zTn=1)*min(2,H) ;

                cplmtQF =   &plaf_qf_4.*(F+R+J+H=0)*((zGn=1 or zWn=1)*(zPn=0) )+
                            &plaf_qf_4.*(zPn+zFn+G+R+nI/2);
            end;
        end;

            avQF    =   round(avQF); 
            cplmtQF =   round(cplmtQF);


/*************************************************************************************************************************************************************/
/*		b. Calcul de l'impot sur le revenu brut, apr�s d�c�te et avant r�ductions et cr�dits d'impot							 		                     */
/*************************************************************************************************************************************************************/

			/*** Application de la d�cote et du bar�me de l imp�t sur le revenu ***/

            array tranche{2};
            array QF_avant_plafond{2};

            do iter=1 to 2; 		/*avec et sans revenu au quotient*/
                do tour = 1 to 2 ; 	/*pour le plafonnement du quotient*/
                    /*La premi�re fois on prend le vrai nombre de part*/ 
                    if tour = 1 then do; 
                        NPARTA = PART;
                    end ; 
                    /*La seconde on prend une ou deux parts*/
                    else do; 
                        if (matn in (1,6)) then NPARTA=2;
                        else if matn in (4) and (ZZN=1) then NPARTA = 2; /*La part donn�e pour un veuf avec enfant entre dans le plafonnement du QF */                                                                      
                        else NPARTA=1;
                    end ;

                    QF_avant_plafond{iter} = round(RICALC{iter}/PART);
                    %Tranche(assiette = QF_avant_plafond{iter} , out_var = tranche{iter}, nb_tranches = &nb_tranches);

                    QF{iter} = round(RICALC{iter}/NPARTA);

                    %Bareme(qf = QF{iter}, rev = RICALC{iter}, npart = NPARTA, out_var = DS{iter}, nb_tranches = &nb_tranches); 

                    if tour = 1 then DSA{iter} = DS{iter}; /* "I" */
                    else DSB{iter} = DS{iter} ;          /* "A" */

                    label      DS1      =     "Imp�t brut ou droits simples hors revenus au quotient (en �)"
                               DS2      =     "Imp�t brut ou droits simples avec revenus au quotient (en �)";
                end ;

			/*** Plafonnement du quotient familial ***/

        		/*D�finition du nombre de parts pour le quotient conjugal : NPARTA*/                                                                         
                if DSB{iter}-DSA{iter}<=avqf then do;
                    DS{iter}=DSA{iter};
                end;
                else do;
                    DS{iter} = max(DSB{iter} - avQF - cplmtQF,DSA{iter});
                end;

                avQFeff{iter} = DSB{iter} - DS{iter} ;

                label   part        =   "Nombre de parts du foyer fiscal"
                        avQF        =   "Plafond avantage d� au QF"
                        avQFeff1    =   "Avantage effectif d� au QF hors quotient"
                        cplmtQF     =   "Compl�ment QF";

            end;

			/*** Calcul de l imp�t r�sultant du bar�me, int�grant l imp�t au quotient apr�s d�c�te et avant r�ductions d imp�t ***/ 

        if (RquotientA) ne 0 then DSPV = DS1 + (DS2-DS1)*(RquotientA/RquotientB);
        else DSPV = DS1 ;


/*************************************************************************************************************************************************************/
/*		c. Application de la d�cote																								 		                     */
/*************************************************************************************************************************************************************/

            if (matn in (2 3 4)) then do;
                if  DSPV <= &plaf_decote_celib. then decote = round(&pente_decote_celib.*(&plaf_decote_celib. - DSPV)); 
                else decote = 0;
            end;

            if (matn in (1 6 )) then do;
                if  DSPV <= &plaf_decote_couple. then decote = round(&pente_decote_couple.*(&plaf_decote_couple. - DSPV)); 
                else decote = 0;
            end;


            DSD = max(DSPV - decote,0);

        decote_imputee = DSPV - DSD ;
        dsd2 = round(dsd) ;

        DSE_bareme = round(DSD);


/*************************************************************************************************************************************************************/
/*		d. Plus-values � taux proportionnel																						 		                     */
/*************************************************************************************************************************************************************/

			/*** Plus-values BA ***/ 

        /*Somme des PV taxables � 16% au forfait et hors forfait*/
        PVBA = &pv_pro_taux.*(_5HX+_5IX+_5JX + _5HE+_5IE+_5JE);

			/*** Plus-values BIC professionnel ***/
 
        BICPmicroPV = &pv_pro_taux.*(max(_5KQ-_5KR,0)+max(_5LQ-_5LR,0)+max(_5MQ-_5MR,0));
        BICPCGAPV = &pv_pro_taux.*(BICPCGAPVdec+BICPCGAPVconj+BICPCGAPVpac);

        PVBICP=BICPmicroPV+BICPCGAPV;

			/*** Plus-values BIC non professionnel ***/
 
        BICNPmicroPV = &pv_pro_taux.*(max(_5NQ-_5NR,0)+max(_5OQ-_5OR,0)+max(_5PQ-_5PR,0));
        BICNPCGAPV = &pv_pro_taux.*(BICNPCGAPVdec+BICNPCGAPVconj+BICNPCGAPVpac);

        PVBICNP = BICNPmicroPV+BICNPCGAPV;

        PVBIC = PVBICP+PVBICNP;

			/*** Plus-values BNC professionnel ***/ 

        BNCPmicroPV = &pv_pro_taux.*(max(_5HR-_5HS,0)+max(_5IR-_5IS,0)+max(_5JR-_5JS,0));
        BNCPCGAPV = &pv_pro_taux.*(BNCPCGAPVdec+BNCPCGAPVconj+BNCPCGAPVpac);

        PVBNCP = BNCPmicroPV+BNCPCGAPV;

			/*** Plus-values BNC non professionnel ***/ 

        BNCNPspecialPV = &pv_pro_taux.*(max(_5KV-_5KW,0)+max(_5LV-_5LW,0)+max(_5MV-_5MW,0));
        BNCNPcontroleePV = &pv_pro_taux.*_5SO;

        PVBNCNP = BNCNPspecialPV+BNCNPcontroleePV;
        PVBNC = PVBNCP+PVBNCNP;

			/*** Autres plus-values ***/ 

        PVautre =  _3sj*&taux_bspce_1. + _3sk*&taux_bspce_2.
                + (_3vd + _3sd) * &pv_titre_taux1. 
                + (_3vi + _3si) * &pv_titre_taux2.
                + (_3vf + _3sf) * &pv_titre_taux3.
                + _3VM * &pv_pea_taux_2. /*entre 2 et 5 ans*/
                + _3vt * &pv_pea_taux_1. /*moins de 2 ans*/
                + (_3VL + _3vg)* &pv_mob_taux.*(1-&switch_pvm.) ;


        PVautre = round(PVautre);

        PVproportionnel = PVautre + PVBA + PVBIC + PVBNC ;

			/*** Masse des plus-values � taux proportionnel ***/

      label     PVproportionnel         =     "Imp�t sur les plus-values � taux proportionnel (en �)" ;


      
/*********************************************************************** RECALCUL DU RFR *********************************************************************/

        if tsb1^=0 then a_sal_rfr = (tsn1/tsb1); else a_sal_rfr = 1 ;  
        if tsb2^=0 then b_sal_rfr = (tsn2/tsb2); else b_sal_rfr = 1 ;  
        if tsb3^=0 then c_sal_rfr = (tsn3/tsb3); else c_sal_rfr = 1 ;  
        if tsb4^=0 then d_sal_rfr = (tsn4/tsb4); else d_sal_rfr = 1 ;  
        if tsb5^=0 then e_sal_rfr = (tsn5/tsb5); else e_sal_rfr = 1 ;  
        if tsb6^=0 then f_sal_rfr = (tsn6/tsb6); else f_sal_rfr = 1 ; 


        rfr_recalc2 = round(ricalc2 

                        /************ Revenus � taux proportionnel **************/

                        /*Plus-values taxables � 16%*/
                        + _5hx + _5ix + _5jx 
                        + _5he + _5ie + _5je 
                        + _5kq + _5lq + _5mq 
                        + _5ke + _5le + _5me
                        + _5nq + _5oq + _5pq 
                        + _5ne +_5oe + _5pe
                        + _5hr + _5ir + _5jr 
                        + _5qd + _5rd + _5sd 
                        + _5kv + _5lv + _5mv
                        + _5so + _5nt + _5ot

                        /*Plus-values et gains divers*/
                        + &rcm_abat_taux.*(_2fu + _2dc)
                        + max(_3va + _3vq - _3vb - _3vr, 0)
                        + _3sg 
                        + _3vd + _3vi + _3vf + _3sd + _3si + _3sf 
                        + _3vm + _3vt /*cloture PEA*/
                        + _3sj + _3sk /*gains de cession de bons de souscription de parts de cr�ateurs d'entreprise*/
                        + _3we 
                  
                        /************ Charges d�duites � r�int�grer *************/
                        + dedPERP
                        
                        /******************* Revenus exon�r�s *******************/
                        /*salari�s*/
                        + (_1au + _1aq + _1dy + _1sm + _1lz)*a_sal_rfr*(_1ak ^= dnts1) 
                        + (_1bu + _1bq + _1ey + _1dn + _1mz)*b_sal_rfr*(_1bk ^= dnts2) 
                        + _1cu*c_sal_rfr*(_1ck ^= dnts3)    
                        + _1du*d_sal_rfr*(_1dk ^= dnts4)  
                        + (_1au + _1aq + _1dy + _1sm + _1lz)*(_1ak = dnts1) 
                        + (_1bu + _1bq + _1ey + _1dn + _1mz)*(_1bk = dnts2)
                        + _1cu*(_1ck = dnts3)    
                        + _1du*(_1dk = dnts4)
                        /*retraites*/
                        + _1at +_1bt
                        /*revenus professionnels exon�r�s des ind�pendants*/
                        + _5hn + _5in + _5jn + _5hb + _5hh + _5ib + _5ih + _5jn
                        + _5jh + _5kn + _5ln + _5mn + _5kb + _5kh + _5lb + _5lh
                        + _5mb + _5mh + _5nn + _5on + _5pn + _5nb + _5nh + _5ob
                        + _5oh + _5pb + _5ph + _5hp + _5ip + _5jp + _5qb + _5qh
                        + _5rb + _5rh + _5sb + _5sh + _5th + _5uh + _5vh + _5hk
                        + _5ik + _5jk + _5kk + _5lk + _5mk 
                        + _5tf + _5ti + _5uf + _5ui + _5vi + _5vf /*honoraires de prospection exon�r�s*/
                        + _3vc /*capital-risque*/ 
                        + _3vp /*jeunes entreprises innovantes*/
                        + _3vy /*groupe familial*/
                        + _2dm /*rcm de source �trang�re des impatri�s*/
                        + _5tc +_5uc + _5vc /*inventeur de produits tax�s � 16%*/
                        + _5ql + _5rl + _5sl + _5sv + _5sw + _5sx /*jeunes cr�ateurs*/
                        + _1ac + _1bc + _1cc + _1dc - _1ae - _1be -_1ce -_1de -_1ad - _1bd - _1cd - _1dd /*salaires exon�r�s de source �trang�re*/
                        + _1ah + _1bh + _1ch + _1dh /*pensions exon�r�es de source �trang�re*/
						
                        /**** Pr�l�vement obligatoire ou retenue � la source ****/ 
                        + _2ee + _2dh 	/*assurance vie et autres rcm soumis au PL*/
                        + _8by +_8cy 	/*elus locaux*/
                        + BICpae
                        + BNCpae
						
                        /******** A remettre dans le revenu imposable ***********/ 
                        + _3vz /*plus-values de cession d'immeubles*/ 
                        + _8zh /*valeur locative de l'habitation*/
                        );



/*************************************************************************************************************************************************************/
/*				7 - R�duction et cr�dit d imp�t																						 						 */
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/*		a. R�ductions d impot																						 		             			         */
/*************************************************************************************************************************************************************/

			/*** Cotisation d assurance pour la for�t ***/
         redAssuranceForet = round(&foret_ass_taux.*min(_7ul , &foret_trav_seul_plaf.*(matn in (1 6)) + &foret_trav_couple_plaf.*(matn in (2 3 4)) ));
         label redAssuranceForet = "R�duction d impots - Cotisations d'assurance pour la for�t";

            /*Contributions sur les hauts revenus �trangers*/
            crHautRevEtr = 0 ;
            label crHautRevEtr = "CI CONTRIBUTIONS SUR LES HAUTS REVENUS ETRANGERS";

			/*** Dons effecu�s � des organismes d aide aux personnes en difficult� (art. 200) ***/ 
        redDONSoeuvres1=round(&dons_difficult_taux.*min(_7Ud,&dons_difficult_plaf.));
        label   redDONSoeuvres1  =  "Dons effectu�s � des organismes d'aide aux personnes en difficult� (art. 200)";

			/*** Salari� � domicile (art. 199 sexdecies) ***/
        varTemporaire   =  (_7DG=0)*min((&sal_dom_plaf.*(_7DQ=0)+ &sal_dom_plaf_max.*(_7DQ=1)+&sal_dom_enf_charge_majo.*( (age1>=&age_seuil.)+(age2>=&age_seuil.) + _7DL + F+J+N + H/2)),
                                       &sal_dom_plaf_max.*(_7DQ=0)+ &sal_dom_1ere_emb_plaf.*(_7DQ=1))
                             + (_7DG ne 0)*&sal_dom_inv_plaf.; /*plafond de la base de r�duction*/

        DepRed                      =   max(min( varTemporaire,_7DD+_7DF),0);
        redSalarieDomicile          =   round(&sal_dom_taux.*DepRed); 
        label   redSalarieDomicile   =  "R�duction d impots pour l'emploi d'un salari� � domicile";

			/*** Int�r�ts au titre du diff�r� de paiement accord� aux agriculteurs (art. 199 vicies A) ***/
        redInteretsAgri=round(&diff_agri_taux.*min( _7UM,&diff_agri_seul_plaf*(matn in (2 3 4))+&diff_agri_couple_plaf*(matn in (1 6)) ));
        label   redInteretsAgri  =  "R�duction d impots - Int�r�ts au titre du diff�r� de paiement accord� aux agriculteurs (art. 199 vicies A)";

			/*** D�fense des for�ts contre l incendie ***/

        redDefenseIncendie=round(&foret_cot_taux. *min(_7UC,&foret_cot_plaf));
        label   redDefenseIncendie   =  "R�duction d impots - D�fense des for�ts contre l'incendie";

			/*** FIPDom: fonds d investissements de proximit� investis outre-mer par des personnes domicili�s outre-mer ***/
        redFipDom = round(&fip_dom_taux.*min(_7FL, &fip_couple_dom_plaf. *(matn in (1 6)) + &fip_seul_dom_plaf.*(matn in (2 3 4))));
        label   redFipDom =  "R�duction d impots - fonds d'investissements de proximit� d�di�s aux entreprises DOM";

			/*** FIPC: fonds d investissements de proximit� d�di�s aux entreprises corses ***/
        redFIPC     =   round(&fip_corse_taux.*min(_7FM, &fip_couple_corse_plaf. *(matn in (1 6)) + &fip_seul_corse_plaf.*(matn in (2 3 4))));
        label   redFIPC  =  "R�duction d impots - fonds d'investissements de proximit� d�di�s aux entreprises corses";

			/*** Souscriptions au capital de SOFICA ***/
        plafond     =   max(0,min(&sofica_plaf_taux.*RBGDa,&sofica_plaf.));
        Dep40       =   max((min(plafond,_7FN+_7GN)-_7GN),0); 
        red40       =   round(&sofica_ded_taux1.*Dep40);
        red48       =   round(&sofica_ded_taux2.*min(_7GN,plafond));
        redSOFICA   =   red40+red48;
        label   redSOFICA    =  "R�duction d impots - Souscription au capital SOFICA";

			/*** D�penses de restauration immobili�re en secteur sauvegard� ou assimil� ***/
        RedRestauImmo       =   &rest_immo_taux4.*min(_7rd,&rest_immo_plaf. ) 
                            +   &rest_immo_taux3.*min(_7rb, max(0,&rest_immo_plaf. -_7rd))
                            +   &rest_immo_taux2.*min(_7rc, max(0,&rest_immo_plaf. - (_7rd + _7rb)))
                            +   &rest_immo_taux2.*min(_7Rf, max(0,&rest_immo_plaf. - (_7rd + _7rb + _7rc))) 
                            +   &rest_immo_taux5.*min(_7Ra, max(0,&rest_immo_plaf. - (_7rd + _7rb + _7rc + _7rf)))
                            +   &rest_immo_taux1.*min(_7Re, max(0,&rest_immo_plaf. - (_7rd + _7rb + _7rc + _7rf + _7ra)))
                            +   &rest_immo_taux5.*min(_7Sy, max(0,&rest_immo_plaf. - (_7rd + _7rb + _7rc + _7rf + _7ra + _7Re)))
                            +   &rest_immo_taux1.*min(_7Sx, max(0,&rest_immo_plaf. - (_7rd + _7rb + _7rc + _7rf + _7ra + _7Re + _7Sy)));

        label   RedRestauImmo    =  "R�duction d impots - D�penses de restauration immobili�re en secteur sauvegard� ou assimil�";

			/*** Int�r�ts d emprunts pour reprise de soci�t� (art. 199 terdecies-0 B) ***/
        redRepriseSociete   =   round(&reprise_soc_taux. *min(_7FH , &int_repr_couple_plaf.*(matn in (1 6)) + &int_repr_seul_plaf.*(matn in (2 3 4))));
        label   redRepriseSociete    =  "R�duction d impots - Int�r�ts d'empr�nts pour reprise de soci�t� (art. 199 terdecies-0 B)";

			/*** Prestations compensatoires (art. 199 octodecies) ***/
        if _7WM=0 then do;
            if _7WN=_7WO then varTemporaire=min(_7WN,&prest_divorce_plaf.);
            else do;
                if _7WO<=&prest_divorce_plaf. then varTemporaire=_7WN;
                else varTemporaire=&prest_divorce_plaf.*_7WN/_7WO;
                end;
              end;
              else do;
                if _7WO<=&prest_divorce_plaf. then varTemporaire=_7WN;
                else varTemporaire=&prest_divorce_plaf.*_7WN/_7WO;
        end;
        redPrestaCompens    =   (round(&divorce_taux.*varTemporaire)+round(&divorce_taux.*_7WP));
        label   redPrestaCompens   =  "R�duction d impots - Prestations compensatoires";

			/*** D�penses d accueil pour personnes �g�es d�pendantes (art. 199 quindecies) ***/
        redDepensesDependance=(round(&age_long_sejour_taux. *min(_7CD,&age_long_sejour_plaf)) + round(&age_long_sejour_taux.*min(_7CE,&age_long_sejour_plaf)));
        label   redDepensesDependance    =  "R�duction d impots - D�penses d'accueil pour personnes �g�es d�pendantes (art. 199 quindecies)";

			/*** Rentes survie, contrat d �pargne handicap (art. 199 septies : 2� et A) ***/
        redRentesSurvie=round(&rente_survie_taux. *min(_7GZ,&rente_survie_plaf+&rente_survie_enf_charge_majo*(F+J+N + H/2 + P/2)));
        label   redRentesSurvie  =  "R�duction d impots - Rentes survie, contrat d'�pargne handicap (art. 199 septies : 2� et A)";

			/*** FCPI : fonds communs de placement dans l innovation (art. 199 terdecies 0 A-VI) ***/
        redFCPI     =   round(&fcpi_taux.*min( _7GQ , &fcpi_couple_plaf. *(matn in (1 6)) + &fcpi_seul_plaf. *(matn in (2 3 4)) ));
        label   redFCPI  =  "R�duction d impots - Fonds communs de placement dans l'innovation (art. 199 terdecies 0 A-VI)";

			/*** FIP : fonds d investissements de proximit� (art. 199 terdecies-0 A-VI bis) ***/
        redFIP      =   round(&fip_taux.*min( _7FQ , &fip_couple_plaf.*(matn in (1 6)) + &fip_seul_plaf.*(matn in (2 3 4)) ));
        label   redFIP   =  "R�duction d impots - fonds d'investissements de proximit� (art. 199 terdecies-0 A-VI bis)";

			/*** R�duction conservation et restauration d objets class�s monuments historique ***/
        redRestauration=round(&monu_hist_taux.*min(&monu_hist_plaf.,_7NZ));
        label   redRestauration  =  "R�duction d impots - Conservation et restauration d'objets class�s monuments historiques";

			/*** Aide aux cr�ateurs d entreprise ***/
        redCreateurEntreprise = &aide_creat_reduc./2      * ( _7ly)
                              + &aide_creat_majo_handi./2 * ( _7my)
                              ;

        label   redCreateurEntreprise    =  "R�duction d impots - Aide aux cr�ateurs d'entreprise";

			/*** Frais de comptabilit� et d adh�sion � un CGA (art. 199 quater B) ***/
        redCGA              =   min(_7FF,(&cga_frais_adh_plaf.*_7FG));
        label   redCGA   =  "R�duction d impots - Frais de comptabilit� et d'adh�sion � un CGA (art. 199 quater B)";

			/*** Frais de scolarisation (art. 199 quater F) ***/
        redFraisScolarisation=(_7EA*&college_reduc.+_7EC*&lycee_reduc.+_7EF*&etab_sup_reduc. + round((_7EB*&college_reduc.+_7ED*&lycee_reduc.+_7EG*&etab_sup_reduc.)/2))/**(CNBCONR=0)*/;
        label   redFraisScolarisation    =  "R�duction d impots - Frais de scolarisation (art. 199 quater F)";

			/*** Dons au profit de fondations et associations reconnues d utilit� publique, ou aux oeuvres/organismes d int�r�t g�n�ral et dons pour le 
				 financement des partis politiques et des campagnes �lectorales,plafond de 20% du revenu imposable appliqu� ***/
        redDONSoeuvres2=round(&dons_utipub_taux.* /*min*/(_7UF + _7VC + _7XS + _7XT + _7XU + _7XW + _7XY));
        label   redDONSoeuvres2  =  "Dons au profit de fondations et associations reconnues d'utilit� publique";

			/*** Investissement locatif Duflot ***/ 
            BaseReduc7GI = min(_7gi, &duflot_plaf_dec.) ;
            BaseReduc7GH = min(_7gh, &duflot_plaf_dec.-BaseReduc7GI) ;
            redInvestLocDuflot = min(round(&duflot_taux1.*BaseReduc7GI/9), 9667) + min(round(&duflot_taux2.*BaseReduc7GH/9),6000)  ; 
            label   redInvestLocDuflot   =  "R�duction d impots - Investissement locatif Duflot";

			/*** Souscription au capital des PME (art. 199 terdecies-0 A) ***/
        redPME1     =   round(&cap_pme_taux1. * min(_7CF, &cap_pme_couple_plaf_2.*(matn in (1 6))+&cap_pme_seul_plaf_2.*(matn in (2 3 4))));
        redPME2     =   round(&cap_pme_taux1. * min(_7CU, &cap_pme_couple_plaf_1.*(matn in (1 6))+&cap_pme_seul_plaf_1.*(matn in (2 3 4))));
        redPME3     =   round(&cap_pme_taux2. * min(_7Cq, &cap_pme_couple_plaf_1.*(matn in (1 6))+&cap_pme_seul_plaf_1.*(matn in (2 3 4))));
        redPME4     =   round(&cap_pme_taux3. * min(_7CL+_7CM+_7CN, &cap_pme_couple_plaf_1.*(matn in (1 6))+&cap_pme_seul_plaf_1.*(matn in (2 3 4))));

        redPME      =   redPME1+redPME2+redPME3+redPME4;
        label   redPME   =  "R�duction d impots - Souscription au capital des PME";

			/*** Investissements forestiers (art. 199 decies H) ***/
        redfForestierAcqui  =   round(&foret_acq_taux. *min( _7UN , &foret_acq_seul_plaf.*(matn in (1 6)) + &foret_acq_couple_plaf.*(matn in (2 3 4)) ));
        redForestierTravaux =   round(&foret_acq_taux.*min( (_7UP) , &foret_trav_seul_plaf.*(matn in (1 6)) + &foret_trav_couple_plaf.*(matn in (2 3 4)) ));
        redForestierContrat =   round(&foret_acq_taux.*min( _7UQ , &foret_contr_seul_plaf.*(matn in (1 6)) + &foret_contr_couple_plaf.*(matn in (2 3 4)) ));
        redForestierReport  =   round(&foret_rep_taux.*min( _7uu + _7te + _7uv + _7tf , &foret_trav_seul_plaf.*(matn in (1 6)) + &foret_trav_couple_plaf.*(matn in (2 3 4)) ))/**(CNBCONR=0)*/;
        
        redInvestForestier =    redfForestierAcqui + redForestierTravaux + redForestierContrat ;
        label   redInvestForestier   =  "R�duction d impots - Investissements forestiers (art. 199 decies H)";

			/*** Investissements locatifs dans le secteur touristique (art. 199 decies E, EA, F, G) ou h�telier � vocation sociale ***/
       redTourisme = &inv_loc_taux1.*(_7xf + _7xi + _7xp + _7xn + _7uy)
                     + &inv_loc_taux2.*(_7xm + _7xj + _7xq + _7xv + _7uz) 
                     + &inv_loc_taux1.*(_7xo + _7xk + _7xr) ;
       label   redTourisme  =  "R�duction d impots - Investissements locatifs dans le secteur touristique (art. 199 decies E, EA, F, G) ou h�telier � vocation sociale";

			/*** R�duction investissement locatif loi Scellier ***/

/*NB : La r�duction est divis�e par 9 car elle est �tal�e sur les neuf ann�es de la location*/ 
                scl_2013_2013 =   min(_7fa,&scl_plaf_dec.)*&scl_met_bbc_taux1./9
                                + min(_7fb,&scl_plaf_dec.)*&scl_met_nonbbc_taux1./9
                                + min(_7fc,&scl_plaf_dec.)*&scl_OM_taux1./9
                                + min(_7fd,&scl_plaf_dec.)*&scl_OM_taux1./9 ; 

                scl_2012_2013 =       (min(_7ja,&scl_plaf_dec.) * &scl_met_bbc_taux1.    )/9
                                    + (min(_7jb,&scl_plaf_dec.) * &scl_met_bbc_taux2.    )/9
                                    + (min(_7jd,&scl_plaf_dec.) * &scl_met_bbc_taux2.    )/9
                                    + (min(_7je,&scl_plaf_dec.) * &scl_met_bbc_taux1.    )/9
                                    + (min(_7jf,&scl_plaf_dec.) * &scl_met_nonbbc_taux1. )/9
                                    + (min(_7jg,&scl_plaf_dec.) * &scl_met_bbc_taux1.    )/9
                                    + (min(_7jh,&scl_plaf_dec.) * &scl_met_bbc_taux1.    )/9
                                    + (min(_7jj,&scl_plaf_dec.) * &scl_met_nonbbc_taux1. )/9
                                    + (min(_7jk,&scl_plaf_dec.) * &scl_OM_taux1.         )/9
                                    + (min(_7jl,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7jm,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7jn,&scl_plaf_dec.) * &scl_OM_taux1.         )/9
                                    + (min(_7jo,&scl_plaf_dec.) * &scl_OM_taux1.         )/9
                                    + (min(_7jp,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7jq,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7jr,&scl_plaf_dec.) * &scl_OM_taux1.         )/9;
         
                scl_2011_2013       = (min(_7NA,&scl_plaf_dec.) * &scl_met_bbc_taux2.    )/9
                                    + (min(_7NB,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7NC,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7ND,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7NE,&scl_plaf_dec.) * &scl_met_bbc_taux2.    )/9
                                    + (min(_7NF,&scl_plaf_dec.) * &scl_met_bbc_taux1.    )/9
                                    + (min(_7NG,&scl_plaf_dec.) * &scl_met_nonbbc_taux2. )/9
                                    + (min(_7NH,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7NI,&scl_plaf_dec.) * &scl_met_nonbbc_taux2. )/9
                                    + (min(_7NJ,&scl_plaf_dec.) * &scl_met_bbc_taux1.    )/9
                                    + (min(_7NK,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7NL,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7NM,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7NN,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7NO,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7NP,&scl_plaf_dec.) * &scl_OM_taux2.         )/9
                                    + (min(_7NQ,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7NR,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7NS,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7NT,&scl_plaf_dec.) * &scl_OM_taux2.         )/9 ;

               scl_2010_2013        = (min(_7HJ,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7HK,&scl_plaf_dec.) * &scl_OM_taux3.         )/9
                                    + (min(_7HN,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7HO,&scl_plaf_dec.) * &scl_OM_taux3.         )/9 ;


               scl_2009_2013        = (min(_7HL,&scl_plaf_dec.) * &scl_met_bbc_taux3.    )/9
                                    + (min(_7HM,&scl_plaf_dec.) * &scl_OM_taux3.         )/9 ;

               scl_report_2012_2012 = _7gj + _7gk + _7gv + _7gw + _7gx ; 
               scl_report_2011_2012 = _7gl + _7gp ;
               scl_report_2010_2012 = _7gs + _7gt ; 
               scl_report_2009_2012 = _7gu ; 

               scl_report_2011_2011 = _7ha + _7hb + _7hg + _7hh ; 
               scl_report_2010_2011 = _7hd + _7he + _7hf  ; 


               scl_report_2010_2010 = _7HV * &scl_met_bbc_taux3. 
                                    + _7HW * &scl_OM_taux3.       
                                    + _7HX * &scl_met_bbc_taux3.  
                                    + _7HZ * &scl_OM_taux3.  ;
               scl_report_2009_2010 = _7HT * &scl_met_bbc_taux3. 
                                    + _7HU * &scl_OM_taux3.    ;

               scl_report_2009_2009 = _7HR * &scl_met_bbc_taux3. 
                                    + _7HS * &scl_OM_taux3.    ;
               
               scl_report_imput     =   _7la + _7lb +_7lc + _7ld + _7le + _7lf 
                                      + _7lm + _7ls + _7lz+ _7mg ;

                ReducScellier       = scl_2013_2013 + scl_2012_2013 + scl_2011_2013 + scl_2010_2013 + scl_2009_2013 
                                    + scl_report_2012_2012 + scl_report_2011_2012 + scl_report_2010_2012 + scl_report_2009_2012 
                                    + scl_report_2011_2011 + scl_report_2010_2011 
                                    + scl_report_2010_2010 + scl_report_2009_2010 
                                    + scl_report_2009_2009 
                                    + scl_report_imput ;
           

            label   ReducScellier    =  "R�duction d impots - Investissement locatif loi Scellier";

			/*** Investissement immobilier dans le secteur de la location meubl�e non professionnelle ***/

/*NB: La r�duction est divis�e par 9 car elle est �tal�e sur les neuf ann�es de la location*/
               Base7JT = min(_7JT, &InvMeuNonPro_plaf.) ;
               Base7JU = min(_7JU, &InvMeuNonPro_plaf.-Base7JT); 
               Base7IE = min(_7IE, &InvMeuNonPro_plaf.) ;
               Base7IF = min(_7IF, &InvMeuNonPro_plaf.-Base7IE); 
               Base7ID = min(_7ID, &InvMeuNonPro_plaf.-Base7IE-Base7IF); 
               Base7IG = min(_7IG, &InvMeuNonPro_plaf.-Base7IE-Base7IF-Base7IF); 
               Base7IL = min(_7IL, &InvMeuNonPro_plaf.); 
               Base7IN = min(_7IN, &InvMeuNonPro_plaf.-Base7IL) ;
               Base7IJ = min(_7IJ, &InvMeuNonPro_plaf.-Base7IL-Base7IN) ;
               Base7IV = min(_7IV, &InvMeuNonPro_plaf.-Base7IL-Base7IN-Base7IJ) ;
               Base7IM = min(_7IM, &InvMeuNonPro_plaf.) ;
               Base7IW = min(_7IW, &InvMeuNonPro_plaf.-Base7IM) ;
               Base7IO = min(_7IO, &InvMeuNonPro_plaf.) ;

               ReducInvMeuNonPro1 =  &InvMeuNonPro_taux1. * Base7JT /9
                                   + &InvMeuNonPro_taux1. * Base7JU /9 ;

               ReducInvMeuNonPro2 =  &InvMeuNonPro_taux2. * Base7IE /9 
                                   + &InvMeuNonPro_taux2. * Base7IF /9 
                                   + &InvMeuNonPro_taux1. * Base7ID /9 
                                   + &InvMeuNonPro_taux1. * Base7IG /9 ;

               ReducInvMeuNonPro3 =  &InvMeuNonPro_taux3. * Base7IL /9 
                                   + &InvMeuNonPro_taux3. * Base7IN /9 
                                   + &InvMeuNonPro_taux2. * Base7IJ /9 
                                   + &InvMeuNonPro_taux2. * Base7IV /9 ;

               ReducInvMeuNonPro4 =  &InvMeuNonPro_taux4. * Base7IM /9 
                                   + &InvMeuNonPro_taux4. * Base7IW /9  ;

               ReducInvMeuNonPro5 =  &InvMeuNonPro_taux4. * Base7IO /9  ;

               ReducInvMeuNonPro6 = min(_7is,DSE_bareme) + min(_7iu,DSE_bareme) + min(_7ix,DSE_bareme) + min(_7iy,DSE_bareme)
                                  + min(_7it,DSE_bareme) + min(_7ih,DSE_bareme) + min(_7jc,DSE_bareme) 
                                  + min(_7iz,DSE_bareme) + min(_7ji,DSE_bareme)
                                  + min(_7js,DSE_bareme) ;

               ReportInvMeuNonPro = min(_7jv,DSE_bareme)
                                    + min(_7jw,DSE_bareme)
                                    + min(_7jx,DSE_bareme)
                                    + min(_7jy,DSE_bareme) 
                                    + min(_7ia,DSE_bareme)
                                    + min(_7ib,DSE_bareme)
                                    + min(_7ic,DSE_bareme)
                                    + min(&InvMeuNonPro_taux4.*_7ip,DSE_bareme)
                                    + min(&InvMeuNonPro_taux4.*_7iq,DSE_bareme)
                                    + min(&InvMeuNonPro_taux4.*_7ir,DSE_bareme)
                                    + min(&InvMeuNonPro_taux4.*_7ik,DSE_bareme)     ;
                               
         ReducInvMeuNonPro = ReducInvMeuNonPro1 + ReducInvMeuNonPro2 + ReducInvMeuNonPro3 + ReducInvMeuNonPro4 + ReducInvMeuNonPro5 + ReducInvMeuNonPro6 + ReportInvMeuNonPro;
         label   ReducInvMeuNonPro    =  "R�duction d impots - Investissement immobilier dans le secteur de la location meubl�e non professionnelle";

			/*** R�duction d imp�t d�penses de protection du patrimoine naturel ***/
        redprotecpat        = round(&protect_nat_taux. *min(_7KA,&protect_nat_plaf.));
        label   redprotecpat     =  "R�duction d impots - D�penses de protection du patrimoine naturel";


/************************************************************************ RI DOM *****************************************************************************/

          PlafA = &OM_lim1.* RICALC1 ; 
          PlafB = &OM_lim2.* RICALC1 ; 
          PlafC = &OM_lim3.* RICALC1 ; 

			/*** [RI pour inv. ds DOM] : investissements DOM dans le logement social ***/
          RepoReducDomSocial=0;        
          RepoReducHKG = min((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)),&OM_taux1.*min(_HKG,DSE_bareme)) ;                                RepoReducDomSocial = RepoReducHKG ;  
          RepoReducHKH = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HKH,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHKH; 
          RepoReducHKI = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HKI,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHKI; 
          RepoReducHQN = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQN,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQN; 
          RepoReducHQU = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQU,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQU; 
          RepoReducHQK = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQK,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQK; 
          RepoReducHQJ = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQJ,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQJ; 
          RepoReducHQS = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQS,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQS ; 
          RepoReducHQW = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQW,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQW; 
          RepoReducHQX = min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HQX,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHQX;                      
           
          RepoReducHRA= min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HRA,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHRA;  
          RepoReducHRB= min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HRB,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHRB;  
          RepoReducHRC= min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HRC,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHRC;  
          RepoReducHRD= min(max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomSocial,0),&OM_taux1.*min(_HRD,DSE_bareme));       RepoReducDomSocial = RepoReducDomSocial + RepoReducHRD; 
            
            redDOMsocial       = RepoReducDomSocial*(1+13/7) ;
            label  redDOMsocial     =  "R�duction d'imp�ts - Investissements DOM dans le logement social";

			/*** [RI pour inv. ds DOM] : investissements DOM entreprises ***/ 
           RepoReducDomEntr=RepoReducDomSocial ; 

           RepoReducHMA = min(&OM_taux3.*min(_HMA,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0)) ;   RepoReducDomEntr = RepoReducDomEntr + RepoReducHMA ; 
           RepoReducHLG = min(&OM_taux5.*min(_HLG,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHLG ; 
           RepoReducHMB = min(&OM_taux3.*min(_HMB,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHMB ;
           RepoReducHMC = min(&OM_taux3.*min(_HMC,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHMC ;
           RepoReducHLH = min(&OM_taux5.*min(_HLH,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHLH ;
           RepoReducHLI = min(&OM_taux5.*min(_HLI,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHLI ;
           RepoReducHQP = min(&OM_taux3.*min(_HQP,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHQP ;
           RepoReducHQG = min(&OM_taux3.*min(_HQG,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));    RepoReducDomEntr = RepoReducDomEntr + RepoReducHQG ;
           RepoReducHPB = min(&OM_taux2.*min(_HPB,DSE_bareme), max((&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1))-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPB ;
           RepoReducHPF = min(&OM_taux2.*min(_HPF,DSE_bareme), max((&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1))-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPF ; 
           RepoReducHPJ = min(&OM_taux2.*min(_HPJ,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0)) ;  RepoReducDomEntr = RepoReducDomEntr + RepoReducHPJ ; 
           RepoReducHQO = min(&OM_taux5.*min(_HQO,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHQO ;
           RepoReducHQF = min(&OM_taux5.*min(_HQF,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1))-RepoReducDomEntr,0)) ;  RepoReducDomEntr = RepoReducDomEntr + RepoReducHQF ;

           RepoReducHPA = min(&OM_taux4.*min(_HPA,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPA ;
           RepoReducHPE = min(&OM_taux4.*min(_HPE,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPE ;
           RepoReducHPI = min(&OM_taux4.*min(_HPI,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPI ;

           RepoReducHPO = min(&OM_taux3.*min(_HPO,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)) -RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPO ;
           RepoReducHPT = min(&OM_taux3.*min(_HPT,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)) -RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPT ;

           RepoReducHPY = min(&OM_taux2.*min(_HPY,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPY ;
           RepoReducHRL = min(&OM_taux2.*min(_HRL,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHRL ;
           RepoReducHRQ = min(&OM_taux2.*min(_HRQ,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHRQ ;
           RepoReducHRV = min(&OM_taux2.*min(_HRV,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHRV ;
           RepoReducHNV = min(&OM_taux2.*min(_HNV,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHNV ;

           RepoReducHPN = min(&OM_taux5.*min(_HPN,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)) -RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPN ;
           RepoReducHPS = min(&OM_taux5.*min(_HPS,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)) -RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPS ;

           RepoReducHPX = min(&OM_taux4.*min(_HPX,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHPX ;
           RepoReducHRK = min(&OM_taux4.*min(_HRK,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ;  RepoReducDomEntr = RepoReducDomEntr + RepoReducHRK ;
           RepoReducHRP = min(&OM_taux4.*min(_HRP,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ;  RepoReducDomEntr = RepoReducDomEntr + RepoReducHRP ;
           RepoReducHRU = min(&OM_taux4.*min(_HRU,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHRU ;
           RepoReducHNU = min(&OM_taux4.*min(_HNU,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHNU ;
           RepoReducHSB = min(&OM_taux2.*min(_HSB,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSB ;
           RepoReducHSG = min(&OM_taux2.*min(_HSG,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSG ;
           RepoReducHSL = min(&OM_taux2.*min(_HSL,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSL ;
           RepoReducHSQ = min(&OM_taux2.*min(_HSQ,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSQ ;
           RepoReducHSV = min(&OM_taux2.*min(_HSV,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSV ;
           RepoReducHTA = min(&OM_taux2.*min(_HTA,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHTA ;
           RepoReducHSA = min(&OM_taux4.*min(_HSA,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSA ;
           RepoReducHSF = min(&OM_taux4.*min(_HSF,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSF ;
           RepoReducHSK = min(&OM_taux4.*min(_HSK,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSK ;
           RepoReducHSP = min(&OM_taux4.*min(_HSP,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));   RepoReducDomEntr = RepoReducDomEntr + RepoReducHSP ;
           RepoReducHSU = min(&OM_taux4.*min(_HSU,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ;  RepoReducDomEntr = RepoReducDomEntr + RepoReducHSU ;
           RepoReducHSZ = min(&OM_taux4.*min(_HSZ,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ;  RepoReducDomEntr = RepoReducDomEntr + RepoReducHSZ ;
          
           RepoReducHPP = min(min(_HPP,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)) -RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHPP ;
           RepoReducHPU = min(min(_HPU,DSE_bareme), max((&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)) -RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHPU ;

           RepoReducHRG = min(min(_HRG,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHRG ;
           RepoReducHRM = min(min(_HRM,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHRM ;
           RepoReducHRR = min(min(_HRR,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHRR ;
           RepoReducHRW = min(min(_HRW,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHRW ;
           RepoReducHNW = min(min(_HNW,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHNW ;
           RepoReducHSC = min(min(_HSC,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHSC ;
           RepoReducHSH = min(min(_HSH,DSE_bareme), max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHSH ;
           RepoReducHSM = min(min(_HSM,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0));  RepoReducDomEntr = RepoReducDomEntr + RepoReducHSM ;
           RepoReducHSR = min(min(_HSR,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ; RepoReducDomEntr = RepoReducDomEntr + RepoReducHSR ;
           RepoReducHSW = min(min(_HSW,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ; RepoReducDomEntr = RepoReducDomEntr + RepoReducHSW ;
           RepoReducHTB = min(min(_HTB,DSE_bareme), max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomEntr,0)) ; RepoReducDomEntr = RepoReducDomEntr + RepoReducHTB ;
     
           RepoReducHSE = min(min(_HSE,DSE_bareme), 270000*(_hqa=0)+plafB*(_hqa=1)); 
           RepoReducHSJ = min(min(_HSJ,DSE_bareme), 270000*(_hqa=0)+plafB*(_hqa=1)); 

           RepoReducHSO = min(min(_HSO,DSE_bareme), 90000*(_hqa=0)+plafC*(_hqa=1)); 
           RepoReducHST = min(min(_HST,DSE_bareme), 90000*(_hqa=0)+plafC*(_hqa=1));

           RepoReducHSY = min(min(_HSY,DSE_bareme), 90000*(_hqa=0)+plafC*(_hqa=1)); 

           RepoReducHTD = min(min(_HTD,DSE_bareme), 90000*(_hqa=0)+plafC*(_hqa=1)); 

           RepoReducHKS = min(min(_HKS,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)); 
           RepoReducHKT = min(min(_HKT,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)); 
           RepoReducHKU = min(min(_HKU,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1));
           RepoReducHQR = min(min(_HQR,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)); 
           RepoReducHQI = min(min(_HQI,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)); 

           RepoReducHPD = min(min(_HPD,DSE_bareme),&OM_plaf.*(_hqa=0)+plafB*(_hqa=1)); 
           RepoReducHPH = min(min(_HPH,DSE_bareme),&OM_plaf.*(_hqa=0)+plafB*(_hqa=1)); 
           RepoReducHPL = min(min(_HPL,DSE_bareme),&OM_plaf.*(_hqa=0)+plafB*(_hqa=1)); 

           RepoReducHPR = min(min(_HPR,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)); 
           RepoReducHPW = min(min(_HPW,DSE_bareme),&OM_plaf.*(_hqa=0)+plafA*(_hqa=1));
 
           RepoReducHRI = min(min(_HRI,DSE_bareme),&OM_plaf.*(_hqa=0)+plafB*(_hqa=1)); 
           RepoReducHRO = min(min(_HRO,DSE_bareme),&OM_plaf.*(_hqa=0)+plafC*(_hqa=1)); 
           RepoReducHRT = min(min(_HRT,DSE_bareme),&OM_plaf.*(_hqa=0)+plafC*(_hqa=1)); 
           RepoReducHRY = min(min(_HRY,DSE_bareme),&OM_plaf.*(_hqa=0)+plafC*(_hqa=1)); 
           RepoReducHNY = min(min(_HNY,DSE_bareme),&OM_plaf.*(_hqa=0)+plafC*(_hqa=1)); 


           RepoReducEntreprise = RepoReducDomEntr - RepoReducDomSocial 
                      + RepoReducHMA*1.5+RepoReducHLG+RepoReducHMB*1.5+RepoReducHMC*1.5+RepoReducHLH+RepoReducHLI+RepoReducHQP*1.5+RepoReducHQG*1.5+RepoReducHPB*5/3+RepoReducHPF*5/3
                      + RepoReducHPJ*5/3+RepoReducHQO+RepoReducHQF+RepoReducHPA*10/9+RepoReducHPE*10/9+RepoReducHPI*10/9+RepoReducHPO*1.5+RepoReducHPT*1.5+RepoReducHPY*5/3+RepoReducHRL*5/3
                      + RepoReducHRQ*5/3+RepoReducHRV*5/3+RepoReducHNV*5/3+RepoReducHPN+RepoReducHPS+RepoReducHPX*10/9+RepoReducHRK*10/9+RepoReducHRP*10/9+RepoReducHRU*10/9+RepoReducHNU*10/9
                      + RepoReducHSB*5/3+RepoReducHSG*5/3+RepoReducHSL*5/3+RepoReducHSQ*5/3+RepoReducHSV*5/3+RepoReducHTA*3/5+RepoReducHSA*10/9+RepoReducHSF*10/9+RepoReducHSK*10/9+RepoReducHSP*10/9+RepoReducHSU*10/9+RepoReducHSZ*10/9 ; 

           redDomEntreprise = _HMM + _HMN + _HQV + _HQE + _HPM + _HRJ + RepoReducEntreprise 
                   + RepoReducHSE + RepoReducHSJ + RepoReducHSO + RepoReducHST + RepoReducHSY + RepoReducHTD + RepoReducHKS + RepoReducHKT + RepoReducHKU + RepoReducHQR + RepoReducHQI  
                   + RepoReducHPD + RepoReducHPH + RepoReducHPL + RepoReducHPR + RepoReducHPW + RepoReducHRI + RepoReducHRO + RepoReducHRT + RepoReducHRY + RepoReducHNY ; 
            label   redDomEntreprise     =  "R�duction d'imp�ts - Investissements DOM entreprises";

			/*** [RI pour inv. ds DOM] : investissements locatifs dans les DOM ***/ 
           RepoReducDomLogement = RepoReducDomEntr ; 
            
           RepoReducHQL = min(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement, min(_HQL,DSE_bareme)) ;              RepoReducDomLogement = RepoReducDomLogement + RepoReducHQL;
           RepoReducHQM = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HQM,DSE_bareme));        RepoReducDomLogement = RepoReducDomLogement + RepoReducHQM;
           RepoReducHQD = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HQD,DSE_bareme));        RepoReducDomLogement = RepoReducDomLogement + RepoReducHQD;
           RepoReducHOB = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HOB,DSE_bareme));        RepoReducDomLogement = RepoReducDomLogement + RepoReducHOB;
           RepoReducHOC = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HOC,DSE_bareme));        RepoReducDomLogement = RepoReducDomLogement + RepoReducHOC;

           RepoReducHOI = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOI,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOI;
           RepoReducHOJ = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOJ,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOJ;
           RepoReducHOK = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOK,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOK;

           RepoReducHOM = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HOM,DSE_bareme)) ;       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOM;     
           RepoReducHON = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HON,DSE_bareme)) ;       RepoReducDomLogement = RepoReducDomLogement + RepoReducHON;

           RepoReducHOP = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOP,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOP;
           RepoReducHOQ = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOQ,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHKH;
           RepoReducHOR = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOR,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOR;
           RepoReducHOT = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOT,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOT;
           RepoReducHOU = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOU,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOU;
           RepoReducHOV = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOV,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOV;
           RepoReducHOW = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOW,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOW;

           RepoReducHOD = min(max(&OM_plaf.*(_hqa=0)+plafA*(_hqa=1)-RepoReducDomLogement,0), min(_HOD,DSE_bareme)) ;       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOD;

           RepoReducHOE = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOE,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOE;
           RepoReducHOF = min(max(&OM_plaf2.*(_hqa=0)+plafB*(_hqa=1)-RepoReducDomLogement,0), min(_HOF,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOF;
           RepoReducHOG = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOG,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOG;
           RepoReducHOX = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOX,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOX;
           RepoReducHOY = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOY,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOY;
           RepoReducHOZ = min(max(&OM_plaf3.*(_hqa=0)+plafC*(_hqa=1)-RepoReducDomLogement,0), min(_HOZ,DSE_bareme));       RepoReducDomLogement = RepoReducDomLogement + RepoReducHOZ;
          

          redDOMLogement =
             _hqb + _hqc + _hqt + _hoa + _hoh + _hol + _hoo + _hos + RepoReducDomLogement - RepoReducDomEntr ; 
           label   redDOMLogement   =  "R�duction d impots - Investissements locatifs dans les DOM";

			/*** R�duction pour les bas revenus (PLF 2017) ***/
	redIR = 0;

    if &switch_redIR. then do;

        if (matn in (2 3 4)) then do;
    seuil1 = &seuil_redIR_1. + &seuil_redIR_dp.*max(part-1,0)*2;
    seuil2=  &seuil_redIR_2. + &seuil_redIR_dp.*max(part-1,0)*2;
    if rfr_recalc2<=seuil1 then redIR=DSE_bareme*&taux_redIR.;
    else if rfr_recalc2<=seuil2 then redIR= DSE_bareme*((-&taux_redIR./(seuil2-seuil1))*rfr_recalc2 + ((&taux_redIR.*seuil2)/(seuil2 - seuil1))) ;
    end;

        if (matn in (1 6)) then do;
    seuil1 = &seuil_redIR_1.*2 + &seuil_redIR_dp.*max(part-2,0)*2;
    seuil2=  &seuil_redIR_2.*2 + &seuil_redIR_dp.*max(part-2,0)*2;
    if rfr_recalc2<=seuil1 then redIR=DSE_bareme*&taux_redIR.;
    else if rfr_recalc2<=seuil2 then redIR= DSE_bareme*((-&taux_redIR./(seuil2-seuil1))*rfr_recalc2 + ((&taux_redIR.*seuil2)/(seuil2 - seuil1))) ;
    end;
    label redIR = "R�duction d'imp�t IR 2017";
    end;

			/*** Total des r�ductions d imp�t ***/
        Reduction       = redAssuranceForet + redDONSoeuvres1   + redSalarieDomicile + redInteretsAgri + redDefenseIncendie + redFipDom + redFIPC + redSOFICA
                            + RedRestauImmo + redRepriseSociete + redPrestaCompens + redDepensesDependance + redRentesSurvie  + redFCPI + redFIP 
                            + redRestauration + redDOMLogement + redCreateurEntreprise + redCGA + redFraisScolarisation + redDONSoeuvres2 
                            + redInvestLocDuflot + redPME + redInvestForestier  + redTourisme   + ReducScellier + ReducInvMeuNonPro + redprotecpat 
                            + redDOMsocial + redDomEntreprise + redIR ;


        label Reduction =   "Montant total des r�ductions d impot" ; 


/*************************************************************************************************************************************************************/
/*		b. Cr�dits d impot non restituables																			 		             			         */
/*************************************************************************************************************************************************************/

/* Note : Les cr�dits d imp�t non restituables s imputent en priorit� sur la cotisation d imp�t sur le revenu (droits issus du bar�me ou proportionnels ou 
		  reprises de r�ductions et cr�dits d imp�t, hors CRL et amendes) puis sur la reprises des accomptes PPE : 
                    - pour le cr�dit issu du code Z8XR => hors imp�t proportionnel
                    - pour les r�ductions "acquisition de biens culturels" et "m�c�nat par l'entreprise" (7UO et 7US) => 
                    hors reprises de r�ductions et cr�dits d imp�t des lignes 8TF et 8TP
                    - pour le cr�dit Corse => hors reprise du cr�dit Corse de la ligne 8TP (cf. r�gles de taxation);										 */

			/*** Cr�dit d imp�t RCM: Z2AB (non restituable) (art. 199 ter - I a b et c) ***/
        cnrRCM      =   _2AB;
        label cnrRCM    =   "Cr�dit d impot non restituable - Revenus de capitaux mobiliers" ; 

			/*** Retenue � la source : 8TA (art. 197 B) ***/

    /*    cnrSource   =   _8TA*(CNBCONR ne 0);
        label cnrSource =   "Cr�dit d imp�t non restituable - Retenue � la source : 8TA (art. 197 B)" ; */

			/*** Cr�dit d imp�t r�sultant de 8XR : revenus NETS de source �trang�re imposables en France (Z8TK = brut) et ouvrant droit � un cr�dit d imp�t 
				 �gal � l IR correspondant � ces revenus ***/
        if RBGpB>0 then cnrEtranger=round(min((_8TK*0.9/RBGpB)*DSPV, DSPV+_8TP+_8TF)) ; 
        else cnrEtranger    =   0;
        label cnrEtranger   =   "Cr�dit d impot non restituable - 8XR : revenus NETS de source �trang�re imposables en France" ; 

			/*** Cr�dit d imp�t r�sultant de 8XP imputable uniquement sur l imp�t proportionnel (PV nettes de sources �trang�res tax�es � 16% en France et 
				 ouvrant droit � un cr�dit d imp�t d �gal montant) ***/
        cnrProportionnel    =  0;
        label cnrProportionnel  =   "Cr�dit d impot non restituable - PV nettes de sources �trang�res tax�es � 16% en France" ; 

			/*** Cr�dit d impot r�sultant de 8XV imputable uniquement sur l imp�t proportionnel correspondant ***/
        cnrInteretsEtr    =  0;
        label cnrInteretsEtr =   "Cr�dit d impot non restituable - Int�r�ts nets de sources �trang�res tax�es � 24% en France" ; 

			/*** Cr�dit d impot r�sultant de 8XF, 8XG et 8XH imputable uniquement sur l imp�t proportionnel correspondant ***/
        cnrGainsEtr    =  0;
        label cnrGainsEtr  =   "Cr�dit d impot non restituable - Gains d'actionnariat salari� sources �trang�res tax�es � 18%, 30% et 41% en France" ; 

			/*** Cr�dit d impot sur les pensions de retraite �trang�res tax�es � 7.5 % ***/  
        cnrRetrEtr   =  /* round(min(0.075*Z8XT, 0.075*(Z1AT + Z1BT)))*/0;
        label cnrRetrEtr  =   "CI SUR PENSIONS DE RETRAITE ETRANGERES TAXEES A  7.5 %;" ; 

			/*** R�duction acquisition de biens culturels : 7UO (art. 238 bis 0-AB) ***/
        cnrBiensCulturels   =   round(&bien_cult_taux.**_7UO);
        label cnrBiensCulturels =   "Cr�dit d impot non restituable - Acquisition de biens culturels : 7UO (art. 238 bis 0-AB)" ; 

			/*** Cr�dit d imp�t pour adh�sion � un groupement de pr�vention agr�� : 8TE ***/
        cnrPrevention       =   _8TE;
        label cnrPrevention =   "Cr�dit d impot non restituable - Adh�sion � un groupement de pr�vention agr�� : 8TE" ; 

			/*** R�duction m�c�nat par l entreprise : 7US (art. 238 bis et 200 bis) ***/
        redMecenat          =   _7US;
        label redMecenat    =   "Cr�dit d impot non restituable - M�c�nat par l'entreprise : 7US (art. 238 bis et 200 bis)" ; 

			/*** Cr�dit pour investissement en Corse : 8TG et 8TO (art. 244 quater E et 199 ter D) ***/
        cnrInvestCorse      =   _8TG+_8TO+_8TP;
        label cnrInvestCorse    =   "Cr�dit d impot non restituable - Investissement en Corse : 8TG, 8TO et 8TP (art. 244 quater E et 199 ter D)" ; 

			/*** Cr�dit d impot recherche : 8TC (art. 199 ter B et 244 quater B) ***/
        cnrRecherche=_8TC;
        label cnrRecherche   =   "Cr�dit d impot recherche : 8TB (art. 199 ter B et 244 quater B)" ; 

			/*** Cr�dit d impot comp�titivit� emploi : 8TB (art. 199 ter B et 244 quater B) ***/
        cnrCICE=_8UW;
        label cnrCICE   =   "Cr�dit d impot comp�titivit� emploi : 8UW (art. 199 ter C et 244 quater C)"  ; 

			/*** Ensemble des cr�dits d impots non restituables ***/
        cnrSousTotal        =  cnrRCM + cnrEtranger + cnrProportionnel + cnrInteretsEtr + cnrGainsEtr + cnrRetrEtr + cnrPrevention + cnrInvestCorse + cnrRecherche + cnrCICE; 
        label cnrSousTotal  =   "Montant total des cr�dit d impots non restituables" ; 


/*************************************************************************************************************************************************************/
/*		c. Cr�dits d impot restituables	(dont PPE)																 			             			         */
/*************************************************************************************************************************************************************/

			/*** Cr�dit d imp�t recherche : 8TB (art. 199 ter B et 244 quater B)***/
        crRecherche=_8TB;
        label crRecherche   =   "Cr�dit d impot recherche : 8TB (art. 199 ter B et 244 quater B)" ; 

			/*** Cr�dit d impot comp�titivit� emploi : 8TB (art. 199 ter B et 244 quater B) ***/
        crCICE=_8TL;
        label crCICE   =   "Cr�dit d impot comp�titivit� emploi : 8TL (art. 199 ter C et 244 quater C)" ; 

			/*** Retenue � la soucre �lus locaux : 8TH (art. 204-0 bis) ***/
        crElusLocaux=_8TH;
        label crElusLocaux  =   "Cr�dit d impot - Retenue � la soucre �lus locaux : 8TH (art. 204-0 bis)" ; 

			/*** Cr�dit d imp�t famille : 8UZ (art. 199 ter E et 244 quater F) ***/
        crFamille=_8UZ;
        label crFamille =   "Cr�dit d impot - Famille : 8UZ (art. 199 ter E et 244 quater F)" ; 

			/*** Cr�dit apprentissage : 8TZ (art. 199 ter F et 244 quater G) ***/
        crApprentissage=_8TZ;
        label crApprentissage   =   "Cr�dit d impot - Apprentissage : 8TZ (art. 199 ter F et 244 quater G)" ; 

			/*** Cr�dit agriculture biologique : 8WA (art. 199 ter K et 244 quater L) ***/
        crAgriBio=_8WA;
        label crAgriBio =   "Cr�dit d impot - Agriculture biologique : 8WA (art. 199 ter K et 244 quater L)" ; 

			/*** Cr�dit d�penses pour prospection commerciale : 8WB (art. 199 ter G et 244 quater H) ***/
        crProspection=_8WB;
        label crProspection =   "Cr�dit d impot - D�penses pour prospection commerciale : 8WB (art. 199 ter G et 244 quater H)" ; 

			/*** Cr�dit d imp�t formation chef d entreprise ***/
        crFormationChef=_8WD;
        label crFormationChef   =   "Cr�dit d impot - Formation chef d'entreprise" ; 

			/*** Cr�dit d imp�t int�ressement ***/
        crInteressement=_8WE;
        label crInteressement   =   "Cr�dit d impot - Interessement" ; 

			/*** Cr�dit d imp�t m�tiers d art ***/
        crMetiersArt=_8WR;
        label crMetiersArt  =   "Cr�dit d impot - M�tiers d'art" ; 

			/*** Cr�dit d imp�t remplacement pour cong� des agriculteurs ***/
        crCongeAgriculteur=_8WT;
        label crCongeAgriculteur    =   "Cr�dit d impot - Remplacement pour cong� des agriculteurs" ; 

			/*** Cr�dit d imp�t ma�tre restaurateur ***/
        crMaitreRestau=_8WU;
        label crMaitreRestau    =   "Cr�dit d impot - Ma�tre restaurateur" ; 

			/*** Cr�dit d imp�t r�novation des d�bits de tabac ***/
        /*crRenovationTabac=_8WV*/
        /*label crRenovationTabac =   "Cr�dit d impot - R�novation des d�bits de tabac"*/ 

			/*** Pr�l�vement lib�ratoire � restituer : 2DH (taxation sp�cifique) ***/
        /* Assurance-vie : credit d impot pour les revenus qui ont ete soumis au prelevement liberatoire alors qu ils pouvaient beneficier de l abattement*/
        ZCH = _2CH ;
        if _2DH>0 then do;
            if      (matn in (1,6))   and 0<=ZCH<&av_couple_abat. then crAssuVie=round(&pfl_avi.*min(_2DH,(&av_couple_abat-ZCH)));
            else if (matn in (2,3,4)) and 0<=ZCH<&av_seul_abat. then crAssuVie=round(&pfl_avi.*min(_2DH,(&av_seul_abat-ZCH)));
            else crAssuVie=0;
        end;
        else crAssuVie=0;
        label crAssuVie =   "Cr�dit d impot - Assurance-vie - Pr�l�vement lib�ratoire � restituer : 2DH" ; 

			/*** Cr�dit d imp�t d�veloppement durable : d�claration 2042 k cases 7tt � 7ty et d�claration 2042 QE ***/

        	/*Mise en place du taux unique � 30% sur le CITE, de fa�on r�troactive pour les d�penses engag�es � partir du 1er septembre 2014*/
            plafond = &plafond_cidd.*(1 + (matn in (1 6))) + &majo_cidd.*(f + j + n + r) + &majo_cidd.*(h + p)/2; 

            crSS = min(_7ss*_7wh,plafond)*&cidd_tx_6_b.                      ; plafond = plafond - min(crSS/&cidd_tx_6_b.,plafond);
            crST = min(_7st*_7wh,plafond)*&cidd_tx_6_b.                      ; plafond = plafond - min(crST/&cidd_tx_6_b.,plafond); 
            crSN = min(_7sn*_7wh,plafond)*&cidd_tx_5_b.                      ; plafond = plafond - min(crSN/&cidd_tx_5_b.,plafond); 
            crSQ = min(_7sq*_7wh,plafond)*&cidd_tx_5_b.                      ; plafond = plafond - min(crSQ/&cidd_tx_5_b.,plafond); 
            crSR = min(_7sr*_7wh,plafond)*&cidd_tx_5_b.                      ; plafond = plafond - min(crSR/&cidd_tx_5_b.,plafond); 
            crSS2 = min(_7ss*(1-_7wh),plafond)*&cidd_tx_6.*(crss=0)          ; plafond = plafond - min(crSS2/&cidd_tx_6.,plafond); 
            crSt2 = min(_7st*(1-_7wh),plafond)*&cidd_tx_6.*(crst=0)          ; plafond = plafond - min(crSt2/&cidd_tx_6.,plafond); 
            crSV = min(_7sv,plafond)*&cidd_tx_6.                             ; plafond = plafond - min(crSV/&cidd_tx_6.,plafond); 
            crSE = min(_7se*_7wh,plafond)*&cidd_tx_4_b.                      ; plafond = plafond - min(crSE/&cidd_tx_4_b.,plafond); 
            crSN2 = min(_7sn*(1-_7wh),plafond)*&cidd_tx_5.*(crSN=0)          ; plafond = plafond - min(crSN2/&cidd_tx_5.,plafond); 
            crSq2 = min(_7sq*(1-_7wh),plafond)*&cidd_tx_5.*(crSq=0)          ; plafond = plafond - min(crSq2/&cidd_tx_5.,plafond); 
            crSR2 = min(_7sr*(1-_7wh),plafond)*&cidd_tx_5.*(crSr=0)          ; plafond = plafond - min(crSR2/&cidd_tx_5.,plafond); 

            cond_crSG = (_7wH*_7wC)> 0 ;
            crSG = min(_7sg*cond_crSG,plafond)*&cidd_tx_3_b.                 ; plafond = plafond - min(crSG/&cidd_tx_3_b.,plafond); 

            cond_crSh = (_7wH*_7VG)> 0 ;
            crSH = min(_7sh*cond_crSH,plafond)*&cidd_tx_3_b.                 ; plafond = plafond - min(crSH/&cidd_tx_3_b. ,plafond); 
            crSO = min(_7so*_7wh,plafond)*&cidd_tx_3_b.                      ; plafond = plafond - min(crSO/&cidd_tx_3_b.,plafond); 
            crSP = min(_7sp*_7wh,plafond)*&cidd_tx_3_b.                      ; plafond = plafond - min(crSP/&cidd_tx_3_b. ,plafond); 
            crSD = min(_7sd*_7wh,plafond)*&cidd_tx_1_b.                      ; plafond = plafond - min(crSD/&cidd_tx_1_b. ,plafond); 
          
            cond_crSJ = (_7WH*_7wT )>0 ;
            crSJ = min(_7sj*cond_crSJ,plafond)*&cidd_tx_1_b.                 ; plafond = plafond - min(crSJ/&cidd_tx_1_b.,plafond); 
            crSE2 = min(_7se*(1-_7wh),plafond)*&cidd_tx_4.*(crSE=0)          ; plafond = plafond - min(crSE2/&cidd_tx_4.,plafond); 
            crSF = min(_7sf,plafond)*&cidd_tx_3.                             ; plafond = plafond - min(crSF/&cidd_tx_3.,plafond); 
            
            crSG2 = min(_7sg,plafond)*&cidd_tx_3.*(crsg=0)        ; plafond = plafond - min(crSG2/&cidd_tx_3.,plafond); 

            crSH2 = min(_7sh,plafond)*&cidd_tx_3.*(crsh=0)        ; plafond = plafond - min(crSH2/&cidd_tx_3.,plafond); 
            crSI = min(_7si,plafond)*&cidd_tx_3.                             ; plafond = plafond - min(crSI/&cidd_tx_3.,plafond); 
            crSO2 = min(_7so*(1-_7wh),plafond)*&cidd_tx_3.*(crSo=0)          ; plafond = plafond - min(crSO2/&cidd_tx_3.,plafond); 
            crSP2 = min(_7sp*(1-_7wh),plafond)*&cidd_tx_3.*(crSp=0)          ; plafond = plafond - min(crSP2/&cidd_tx_3.,plafond); 
            crSU = 0                                                         ; plafond = plafond - min(crSU/&cidd_tx_3. ,plafond); 
            crSW = min(_7sw,plafond)*&cidd_tx_3.                             ; plafond = plafond - min(crSW/&cidd_tx_3.,plafond); 
            crSM = 0                                                         ; plafond = plafond - min(crSM/&cidd_tx_2.,plafond); 
            crSD2 = min(_7sd*(1-_7wh),plafond)*&cidd_tx_1.*(crsd=0)          ; plafond = plafond - min(crSD2/&cidd_tx_1.,plafond); 
                
            cond_crSJ2 = (1-_7wt)*(1-_7wk)+_7wh*_7wk> 0 ;
            cond_crSJ3 = _7wt*(1-_7wk)> 0 ;
            cond_crSJ4 = max(cond_crSJ3,cond_crSJ2)*(1-cond_crSJ) ;
            crSJ2 = min(_7sj*cond_crSJ4,plafond)*&cidd_tx_1.                 ; plafond = plafond - min(crSJ2/&cidd_tx_1.,plafond); 
                  
            cond_crSK = (1-_7wk*(1-_7wh))> 0 ;
            crSK  = min(_7sk*cond_crSK,plafond)*&cidd_tx_1.                  ; plafond = plafond - min(crSK/&cidd_tx_1.,plafond);   

            cond_crSL = (1-_7wk*(1-_7wh)) > 0 ;
            crSL  = min(_7sl*cond_crSL,plafond)*&cidd_tx_1.                  ; plafond = plafond - min(crSL/&cidd_tx_1.,plafond);  
     
            crDvtDurable = crSS + crST + crSN + crSQ + crSR + crSS2 + crSt2 + crSV + crSE + crSN2 + crSq2 + crSR2 + crSG + crSH + crSO + crSP + crSD +
                   crSJ + crSe2 + crSF + crSG2 + crSH2 + crSI + crSO2 + crSP2 + crSU + crSW + crSM + crSD2 + crsj2 + crSK + crSL ;
 
            crDvtDurable = crDvtDurable*&switch_calc_elast. ;

			/*** Cr�dit d imp�t d�penses en faveur de l aide aux personnes r�alis�es dans l habitation principale :  7WJ et 7WL(art. 200 quater A) ***/
        plafond         =   &gros_equip_seul_plaf.*(matn in (2 3 4)) + &gros_equip_couple_plaf.*(matn in (1 6)) + &gros_equip_majo.*(F+J+N+R + H/2 + P/2);
        creditGrosEq1   =   round(&ci_aidepers_hab_taux2.*min(_7wj,plafond));
        creditGrosEq2   =   round(&ci_aidepers_hab_taux1.*min(_7wl,plafond-min(_7wj,plafond)));
        crGrosEquipement=   (creditGrosEq1+creditGrosEq2)*(_7WE=0);
        label crGrosEquipement  =   "Cr�dit d impot - D�penses en faveur de l'aide aux pers. dans l'habitation principale : 7WJ et 7WL(art. 200 quater A)" ; 

			/*** Cr�dit d imp�t auto-entrepreneur ***/
        crAUtoEnt       =   _8UY;
        label crAUtoEnt =   "Cr�dit d impot - Auto-entrepreneur" ; 

			/*** Cr�dit repr�sentatif de la taxe additionnelle au droit de bail de 1998 : 4TQ (art. 234 nonies et suivants) ***/
        crDroitBail     =   round(_4TQ*&droit_bail_taux.);
        label crDroitBail   =   "Cr�dit d impot - Taxe additionnelle au droit de bail de 1998 : 4TQ (art. 234 nonies et suivants)" ; 

			/*** Cr�dit d imp�t frais de garde des jeunes enfants : 7GA � 7GM (art. 200 quater B) ***/
        crGardeEnfant   =   round(&garde_enf_taux.*( min(_7GA,&garde_enf_plaf.) + min(_7GB,&garde_enf_plaf.) + min(_7GC,&garde_enf_plaf.)  + 
                            min(_7GE,&garde_enf_alt_plaf.) + min(_7GF,&garde_enf_alt_plaf.) + min(_7GG,&garde_enf_alt_plaf.) ));
        label crGardeEnfant =   "Cr�dit d impot - Frais de garde des jeunes enfants : 7GA � 7GM (art. 200 quater B)" ; 

			/*** Cr�dit d imp�t int�r�ts pr�t �tudiant : 7UK (art. 200 terdecies) ***/
        crEtudiant      =   round(&int_pret_etud_taux.*min(_7UK,&int_pret_etud_plaf.)+0.25*min(_7TD,&int_pret_etud_plaf.*_7VO));
        label crEtudiant    =   "Cr�dit d impot - Int�r�ts pr�t �tudiant : 7UK (art. 200 terdecies)" ; 

			/*** Cr�dit d imp�t emploi d un salari� � domicile ***/
        varTemporaireCrSAD  =  (_7DG=0)*min((&sal_dom_plaf.*(_7DQ=0)+ &sal_dom_plaf_max.*(_7DQ=1)+&sal_dom_enf_charge_majo.*( (age1>=&age_seuil.)+(age2>=&age_seuil.) + F+J+N + H/2)),
                                &sal_dom_plaf_max.*(_7DQ=0)+ &sal_dom_1ere_emb_plaf.*(_7DQ=1))
                                + (_7DG ne 0)*&sal_dom_inv_plaf.; *plafond de la base de r�duction;
        plaf_sap = varTemporaireCrSAD  ;
        crSalarieDomicile=  round(&sal_dom_taux.*min(varTemporaireCrSAD,_7DB));

        label crSalarieDomicile =   "Cr�dit d impot - Emploi d'un salari� � domicile" ; 

			/*** Cr�dit d imp�t inter�t d emprunt ***/
        plafond         =   ((zPn+zFn+G+R+nI)=0)*(&int_empr_seul_plaf*(matn in (2 3 4)) + 2*&int_empr_seul_plaf*(matn in (1 6)) + &int_empr_charge_majo*(F+J+N+(H+P)/2))
                            +((zPn+zFn+G+R+nI) ne 0)*(2*&int_empr_seul_plaf*(matn in (2 3 4)) + 4*&int_empr_seul_plaf*(matn in (1 6)));
        
        Base7VY         =   min(_7VY,plafond);
        Base7VZ         =   min(_7VZ,max(0,plafond-Base7VY));
        Base7VW         =   min(_7VW,max(0,plafond-Base7VZ));
        Base7VV         =   min(_7VV,max(0,plafond-Base7VW));
        Base7VU         =   min(_7VU,max(0,plafond-Base7VV));
        Base7VT         =   min(_7VT,max(0,plafond-Base7VU));
        Base7VX         =   min(_7VX,max(0,plafond-Base7VT));
        crInteretEmprunt=   round(&int_empr_taux3.*Base7VY
                                + &int_empr_taux1.*Base7VZ 
                                + &int_empr_taux2.*Base7VW
                                + &int_empr_taux4.*Base7VV 
                                + &int_empr_taux5.*Base7VU 
                                + &int_empr_taux6.*Base7VT 
                                + &int_empr_taux3.*Base7VX );
        label crInteretEmprunt  =   "Cr�dit d impot - Inter�t d'emprunt pour l'acquisition de l'habitation principale" ; 

        crInteretEmprunt = crInteretEmprunt*&switch_calc_elast. ;

			/*** Cr�dit d imp�t primes d assurance pour loyers impay�s : 4BF (art. 200 nonies) ***/
        crPrimesAssurance=  round(&assur_loy_imp_taux.*_4BF);
        label crPrimesAssurance =   "Cr�dit d impot - Primes d assurance pour loyers impay�s : 4BF (art. 200 nonies)" ; 

			/*** Cr�dit d imp�ts pour les travaux de pr�vention des risques technologiques dans les logements donn� en location ***/
        plafond_travtech = &prev_risque_seul_plaf. * (matn in (2 3 4))
                         + &prev_risque_couple_plaf. * (matn in (1 6))
                         + &prev_risque_pac_majo. * (F+J+N+R + H/2 + P/2);

        crTravTech      =   &prev_risque_taux.*min(plafond_travtech, _7WR);
        label crTravTech    =   "Cr�dit d imp�t - Travaux de pr�vention des risques technologiques dans les logements donn� en location" ; 

			/*** Cr�dit d imp�ts pour les d�penses en faveur de la qualit� environnementale des logements donn�s en location ***/
        crQualEnv = min(_7sz, &qualenv_plaf.) ;
        label crQualEnv    =   "Cr�dit d'imp�t - Travaux de pr�vention des risques technologiques dans les logements donn� en location" ;

			/*** Cotisations syndicales (art. 199 quater c) ***/

/*Les revenus salariaux NE sont PAS pris en compte dans la base de la r�duction si les frais r�els d�clar�s par le titulaire ont effectivement �t� imput�s 
(frais r�els sup�rieurs � la d�duction forfaitaires pour frais)*/
/*Attention, ce montant ne peut pas exc�der 1% du salaire vers� au contribuable*/
        varTemporaire               =   (_1AJ + _1AP + _1TV+_1TW+_1TX 
                                        + _1AS + _1AO)*(_1AK < DNTS1 or _1AK=0);

        REDN1                       =   round(&cot_syndic_taux.*min(_7AC,(&cot_syndic_plaf.*varTemporaire)));

        varTemporaire               =   (_1BJ + _1BP + _1UV +_1UW +_1UX 
                                        + _1BS + _1BO)*(_1BK < DNTS2 or _1BK=0);
        REDN2                       =   round(&cot_syndic_taux.*min(_7AE,(&cot_syndic_plaf.*varTemporaire)));

        varTemporaire               =   (_1CJ + _1CP + _1CS + _1CO)*(_1CK < DNTS3 or _1CK=0) + 
                                        (_1DJ + _1DP + _1DS + _1DO)*(_1DK < DNTS4 or _1DK=0) + 
                                        (_1EJ + _1EP + _1ES + _1EO)*(_1EK < DNTS5 or _1EK=0) +
                                        (_1FJ + _1FP + _1FS + _1FO)*(_1FK < DNTS6 or _1FK=0);

        REDN3                       =   round(&cot_syndic_taux.*min(_7AG,(&cot_syndic_plaf.*varTemporaire)));


        crCotisationsSyndicales    =   (REDN1+REDN2+REDN3);
        label   crCotisationsSyndicales     =  "Cr�dit d impot restitable - cotisations syndicales (art. 199 quater c)";


			/*** Cr�dit d imp�t prime pour l emploi (PPE) ***/
        %if &switch_ppe.=1 %then %do ;

		/** Calcul du revenu d activit� professionnelle **/
            	/*D�clarant*/
                salarieDEC      =   round(_1AJ+_1AU+_3VJ+_1TV+_1TW+_1TX+_1AQ+_1LZ);
                
                nonSalarieDEC   =   round(1.1111*max(0,
                                                    _5HN+_5HO+_5HW+_5HB+_5HC-_5HF+_5HH+_5HI-_5HL+_5HD+
                                                    _5KN+KOtax+KPtax+_5KX+_5KB+_5KC-_5KF+_5KH+_5KI+_5KA-_5KL+
                                                    _5HP+HQtax+_5HV+_5QB+_5QC-_5QE+_5QH+_5QI-_5QK+TETAX+TATAX+TBTAX)  
                                        +0.8889*min(0,
                                                    _5HN+_5HO+_5HW+_5HB+_5HC-_5HF+_5HH+_5HI-_5HL+_5HD+
                                                    _5KN+KOtax+KPtax+_5KX+_5KB+_5KC-_5KF+_5KH+_5KI+_5KA-_5KL+
                                                    _5HP+HQtax+_5HV+_5QB+_5QC-_5QE+_5QH+_5QI-_5QK+TETAX+TATAX+TBTAX));   
                
	            /*Conjoint*/
                salarieCONJ     =   round(_1BJ+_1BU+_3VK+_1UV+_1UW+_1UX+_1BQ/*+ZRBJ*/+_1MZ);
                
                nonSalarieCONJ  =   round(1.1111*max(0,
                                                    _5IN+_5IO+_5IW+_5IB+_5IC-_5IF+_5IH+_5II-_5IL+_5ID+ 
                                                    _5LN+LOtax+LPtax+_5LX+_5LB+_5LC-_5LF+_5LH+_5LI+_5LA-_5LL+
                                                    _5IP+IQtax+_5IV+_5RB+_5RC-_5RE+_5RH+_5RI-_5RK+UETAX+UATAX+UBTAX)  
                                        +0.8889*min(0,
                                                    _5IN+_5IO+_5IW+_5IB+_5IC-_5IF+_5IH+_5II-_5IL+_5ID+ 
                                                    _5LN+LOtax+LPtax+_5LX+_5LB+_5LC-_5LF+_5LH+_5LI+_5LA-_5LL+
                                                    _5IP+IQtax+_5IV+_5RB+_5RC-_5RE+_5RH+_5RI-_5RK+UETAX+UATAX+UBTAX));
                
            	/*Personnes � charge*/
                salariePAC1     =   round(_1CJ+_1CU);                              
                salariePAC2     =   round(_1DJ+_1DU);                              
                salariePAC      =   salariePAC1+salariePAC2;

                nonSalariePAC   =   round(1.1111*max(0,
                                                    _5JN+_5JO+_5JW+_5JB+_5JC-_5JF+_5JH+_5JI-_5JL+_5JD+
                                                    _5MN+MOtax+MPtax+_5MX+_5MB+_5MC-_5MF+_5MH+_5MI+_5MA-_5ML+
                                                    _5JP+JQtax+_5JV+_5SB+_5SC-_5SE+_5SH+_5SI-_5SK + VETAX+VATAX+VBTAX)  
                                            +0.8889*min(0,
                                                    _5JN+_5JO+_5JW+_5JB+_5JC-_5JF+_5JH+_5JI-_5JL+_5JD+
                                                    _5MN+MOtax+MPtax+_5MX+_5MB+_5MC-_5MF+_5MH+_5MI+_5MA-_5ML+
                                                    _5JP+JQtax+_5JV+_5SB+_5SC-_5SE+_5SH+_5SI-_5SK + VETAX+VATAX+VBTAX));
                
		/** S�rie de retraitement pour savoir qui a effectivement droit � la PPE **/
/*Cette partie vise � corriger les erreurs qui peuvent se glisser au moment de cocher la case "droit � la PPE", selon les conventions de la DGFIP */
              	/*Retraitements pour l activit� salari�e*/
                if salarieDEC   =   0   then do; _1av=0;_1ax=0; end;
                if salarieCONJ  =   0   then do; _1bv=0;_1bx=0; end;
                if salariePAC1  =   0   then do; _1cv=0;_1cx=0; end;
                if salariePAC2  =   0   then do; _1dv=0;_1dx=0; end;
                
                if _1aj =0 and salarieDEC  ne 0 and _1av=0 then _1ax=1;
                if _1bj =0 and salarieCONJ ne 0 and _1bv=0 then _1bx=1;
                if _1cj =0 and salariePAC1 ne 0 and _1cv=0 then _1cx=1;
                if _1dj =0 and salariePAC2 ne 0 and _1dv=0 then _1dx=1;
                
              	/*Retraitements pour l activit� non-salari�e*/
                if nonSalarieDEC    >0  and _5NV=0 then _5NW=1;
                if nonSalarieCONJ   >0  and _5OV=0 then _5OW=1;
                if nonSalariePAC    >0  and _5PV=0 then _5PW=1;

                if nonSalarieDEC    =0  then do; _5nv=0;_5nw=0; end;
                if nonSalarieCONJ   =0  then do; _5ov=0;_5ow=0; end;
                if nonSalariePAC    =0  then do; _5pv=0;_5pw=0; end;
                
                if _1AJ>0 and _1av=0 and _1ax=0 then do;_5NV=0;_5NW=0;  end;
                if _1BJ>0 and _1bv=0 and _1bx=0 then do;_5OV=0;_5OW=0;  end;
                if _1CJ+_1DJ>0 and _1cv+_1dv=0 and _1cx+_1dx=0 then do;
                    _5PV=0;
                    _5PW=0;
                end;

        		/*Revenu total : activit� salari�e et non salari�e*/
                array salaire{4} salarieDEC salarieCONJ salariePAC1 salariePAC2 ;
                array salaireBis{4};
                array EcartSalaire{4};
                array salaireEQtpsplein{4};

                array nonSalaire{3} nonSalarieDEC nonSalarieCONJ nonSalariePAC;
                array nonSalaireBis{3};
                array EcartnonSalaire{3};
                array nonSalaireEQtpsplein{3};

                array coeffTpsPartiel{5};               /*pourcentage temps partiel relatif � l ann�e ENTIERE*/ 
                array coeffTpsPartielInfraAnnuel{5};    /*en cas de changement de situation de famille*/

                array heure{5}          _1AV _1BV _1CV _1DV zero;
                array TempsPlein{5}     _1AX _1BX _1CX _1DX zero;

                array jourBis{3}        _5NV _5OV _5PV;
                array ActCompleteBis{3} _5NW _5OW _5PW;

                ecartSal    =   0;
                ecartNonSal =   0;

                revkire2=mnrvkh;

		/** Vieillissement des revenus **/ 
            if nbsljj = 0 then nbsljj = 360 ;
            /*Evolution des salaires*/
            do iter= 1 to 4 ;
                /*Application de l augmentation des salaires cf. coup de pouce SMIC*/

                    if ((heure{iter}/1820)+TempsPlein{iter})>=nbsljj/360 then do;
                            /*Si temps plein*/
                            /*En cas d activit� mixte, d�s qu une des activit�s est exerc�e � temps plein, la personne est consid�r�e comme travaillant � 
							  temps plein*/
                            coeffTpsPartiel{iter}  =   nbsljj/360;
                            salaireEQtpsplein{iter}=   salaire{iter}/coeffTpsPartiel{iter};
                            /*Revenu en �quivalent temps plein cf. changement de situation familiale*/

                         end;
                         else do;
                            /*Si temps partiel*/
                            coeffTpsPartiel{iter}=(heure{iter}/1820);
                            if coeffTpsPartiel{iter} ne 0 then salaireEQtpsplein{iter}=salaire{iter}/coeffTpsPartiel{iter};
                            else salaireEQtpsplein{iter}=0;
                            /*Revenu en �quivalent temps plein TOUTE l ann�e malgr� chgt de situation familiale*/
                    end;

                    salaireBis{iter}=salaire{iter};
                    /*NB: on garde en m�moire les salaires originaux*/

                    /*Application de la diffusion de l augmentation des revenus*/
                    salaire{iter}=salaire{iter};

                    EcartSalaire{iter}=salaire{iter}-salaireBis{iter};
                    ecartSal=ecartSal+EcartSalaire{iter};

             end;

		/** Evolution des BA, BIC ,BNC **/
            do iter=1 to 3;

                    if ((jourBis{iter}/360)+ActCompleteBis{iter})>=nbsljj/360 then do;
                            /*Si temps plein*/
                            /*En cas d activit� mixte, d�s qu une des activit�s est exerc�e � temps plein, la personne est consid�r�e comme travaillant � 
							  temps plein*/
                            coeffTpsPartiel{iter}=nbsljj/360;
                            nonSalaireEQtpsplein{iter}=nonSalaire{iter}/coeffTpsPartiel{iter};
                        end;
                        else do;
                            /*Si temps partiel*/
                            coeffTpsPartiel{iter}=(jourBis{iter}/360);
                            if coeffTpsPartiel{iter} ne 0 then nonSalaireEQtpsplein{iter}=nonSalaire{iter}/coeffTpsPartiel{iter};
                            else nonSalaireEQtpsplein{iter}=0;
                            /*Revenu en �quivalent temps plein TOUTE l ann�e malgr� changement de situation familiale*/
                    end;

                    nonSalaireBis{iter}=nonSalaire{iter};
                    /*NB: on garde en m�moire les salaires originaux*/

                    /*Application de la diffusion de l augmentation des revenus*/
                    nonSalaire{iter}=nonSalaire{iter};

                    EcartNonSalaire{iter} = nonSalaire{iter}-nonSalaireBis{iter};
                    ecartNonSal = ecartNonSal+EcartNonSalaire{iter};
                    /*NB: cette augmentation a une r�percussion sur le revenu fiscal de r�f�rence*/

             end;

		/** Actualisation du revenu fiscal **/
                revkire2= revkire2 + ecartSal*0.9 + ecartNonSal;


			/*** Somme des revenus ***/
                revDECvrai  =   salarieDEC+nonSalarieDEC;
                revCONJvrai =   salarieCONJ+nonSalarieCONJ;
                revPAC1vrai =   salariePAC1 + (nonSalariePAC + salariePAC2)*
                                                (F+H+R+J+N+P=1);
                revPAC2vrai =   salariePAC2*(F+H+R+J+N+P>1);
                revPAC5vrai =   nonSalariePAC*(F+H+R+J+N+P>1);

                /*Pour le calcul*/
                revDEC      =   salarieDEC*(_1av ne 0 OR _1ax ne 0)+nonSalarieDEC; 
                revCONJ     =   salarieCONJ*(_1bv ne 0 OR _1bx ne 0)+nonSalarieCONJ;
                revPAC1     =   salariePAC1*(_1cv ne 0 OR _1cx ne 0) + 
                                (nonSalariePAC + salariePAC2)*(F+H+R+J+N+P=1);
                revPAC2     =   salariePAC2*(F+H+R+J+N+P>1)*(_1dv ne 0 OR _1dx ne 0);
                revPAC5     =   nonSalariePAC*(F+H+R+J+N+P>1);

			/*** Calcul de la part individuelle ***/
                zero        =   0;
                array rev{5} revDEC revCONJ revPAC1 revPAC2 revPAC5;
                array base{5} baseDEC baseCONJ basePAC1 basePAC2 basePAC5;
                array PPEindiv{5} PPEindivDEC PPEindivCONJ PPEindivPAC1 PPEindivPAC2 PPEindivPAC5;
                array PPEindivBis{5} PPEindivDECBis PPEindivCONJBis PPEindivPAC1Bis PPEindivPAC2Bis PPEindivPAC5Bis;

                array jour{5}        _5NV _5OV jour1 zero jour5;
                array ActComplete{5} _5NW _5OW act1  zero act5;

                if F+H+R+J+N+P<2 then do;
                    /*Si temps plein*/
					/*En cas d activit� mixte, d�s qu une des activit�s est exerc�e � temps plein, la personne est consid�r�e comme travaillant � temps plein*/
                    jour1=_5PV; 
                    jour5=0;    
                    act1=_5PW;  
                    act5=0;   
                  end;
                  else do;
                    jour1=0;    
                    jour5=_5PV; 
                    act1=0;     
                    act5=_5PW;
                end;

			/*** Condition de revenu calcul�e au niveau du foyer pour �tre �ligible � la PPE ***/
                if  (matn in (2 3 4) and round(rfr_recalc2*360/nbsljj)>&ppe_foyer1.+&ppe_foyer3.*max(0,(part-1)*2)) 
                 or (matn in (1 6)   and round(rfr_recalc2*360/nbsljj)>&ppe_foyer2.+&ppe_foyer3.*max(0,(part-2)*2))
                 
                    then do; 
                    PPE=0;
                    goto ETIQfinPPE;
                end;
        
                PPE=0;

			/*** Calcul de la PPE "base" ***/
        do iter=1 to 5;

		/** Redressement du nombre d�heures travaill�es **/ 
                if ((heure{iter}/1820)+(jour{iter}/360)+TempsPlein{iter}+ActComplete{iter})>=nbsljj/360 then do;
                    *Temps plein;
                    *En cas d activit� mixte, d�s qu une des activit�s est exerc�e � temps plein, la personne
                    est consid�r�e comme travaillant � temps plein;
                    coeffTpsPartiel{iter}=nbsljj/360;
                    coeffTpsPartielInfraAnnuel{iter}=coeffTpsPartiel{iter};
                    base{iter}=rev{iter}/coeffTpsPartiel{iter};
                    *Revenu en �quivalent temps plein cf. changement de situation familiale;
                   end;
                   else do;
                    *Temps partiel;
                    coeffTpsPartiel{iter}=(heure{iter}/1820)+(jour{iter}/360);
                    coeffTpsPartielInfraAnnuel{iter}=((heure{iter}/1820)+(jour{iter}/360))*(360/nbsljj);

                    if coeffTpsPartiel{iter} ne 0 then base{iter}=rev{iter}/coeffTpsPartiel{iter};
                    else base{iter}=0;
                    *Revenu en �quivalent temps plein TOUTE l ann�e malgr� un changement de situation familiale;
                  end;

			/*** Calcul de la part individuelle ***/ 
                if rev{iter}>=&ppe_indiv1. then do;

                    /*Prime pour une ann�e pleine (ie. prime qui aurait �t� accord�e � temps plein)*/
                    if      &ppe_indiv1.<=base{iter}<=&ppe_indiv2. then PPEindiv{iter}=base{iter}*&ppe_taux1.;
                    else if &ppe_indiv2.<base{iter}<=&ppe_indiv3. then PPEindiv{iter}=(&ppe_indiv3.-base{iter})*&ppe_taux2.;
                    else    PPEindiv{iter}=0;

                    PPEindivBis{iter}=PPEindiv{iter};

                    /*Prime ramen�e � temps partiel + Majoration temps partiel (s il y a lieu)*/
                    if ((heure{iter}/1820)+(jour{iter}/360)+TempsPlein{iter}+ActComplete{iter})<nbsljj/360 then do;
                        if coeffTpsPartielInfraAnnuel{iter}<=0.5 then
                        PPEindiv{iter}=PPEindiv{iter}*coeffTpsPartiel{iter}*(1+&ppe_partiel.);
                        /*Activit� exerc�e � plus de 50%*/
                        else PPEindiv{iter}=
                          PPEindiv{iter}*(&ppe_partiel. + coeffTpsPartiel{iter}*(1-&ppe_partiel.));
                       end;
                    	/*Temps complet sur une p�riode infra annuelle*/
                       else PPEindiv{iter}=PPEindiv{iter}*coeffTpsPartiel{iter};

                            PPEindiv{iter}=round(PPEindiv{iter});
                     end;
                else PPEindiv{iter}=0;
                
                PPE+PPEindiv{iter};
        end;


        PPEindivPAC=PPEindivPAC1+PPEindivPAC2+PPEindivPAC5; 

			/*** Majoration pour couple monoactif ***/
                if matn in (1 6) and revDEC>=&ppe_indiv1. and revCONJvrai<&ppe_indiv1. then do;
                    /*La majoration de &ppe_mono n est jamais proratis�e*/ 
                    if &ppe_indiv1.<=baseDEC<=&ppe_indiv4. then do; 
                        monoactif=&ppe_mono.; 
                        goto etiqMono1; 
                    end;

                    else if (&ppe_indiv4.<baseDEC<=&ppe_indiv5.)then monoactif=(&ppe_indiv5.-baseDEC)*&ppe_taux3.;
                    else monoactif=0;

                    /*Majoration temps partiel*/
                    if ((_1AV/1820)+(_5NV/360)+_1AX+_5NW)<nbsljj/360 then do;
                        if coeffTpsPartielInfraAnnuel1<=0.5 then monoactif=monoactif*coeffTpsPartiel1*(1+&ppe_partiel.);
                        *Activit� exerc�e � plus de 50%;
                        else monoactif=monoactif*(&ppe_partiel. + coeffTpsPartiel1*(1-&ppe_partiel.));
                    end;
                    /*Temps complet sur une p�riode infra annuelle*/
                    else monoactif=monoactif*coeffTpsPartiel1;

                    etiqMono1:
                    end;
                    else if matn in (1 6) and revCONJ>=&ppe_indiv1. and revDECvrai<&ppe_indiv1. then do;

                    /*La majoration de &ppe_mono n est jamais proratis�e*/ 
                    if &ppe_indiv1.<=baseCONJ<=&ppe_indiv4. then do; 
                    monoactif=&ppe_mono.; 
                    goto etiqMono2; 
                    end;
                    else if (&ppe_indiv4.<baseCONJ<=&ppe_indiv5.)then monoactif=(&ppe_indiv5.-baseCONJ)*&ppe_taux3.;
                    else monoactif=0;

                    /*Majoration temps partiel*/
                    if ((_1BV/1820)+(_5OV/360)+_1BX+_5OW)<nbsljj/360 then do;
                        if coeffTpsPartielInfraAnnuel2<=0.5 then
                        monoactif=monoactif*coeffTpsPartiel2*(1+&ppe_partiel.);
                        /*Activit� exerc�e � plus de 50%*/
                        else monoactif=monoactif*(&ppe_partiel. + coeffTpsPartiel2*(1-&ppe_partiel.));
                    end;

                    /*Temps complet sur une p�riode infra annuelle*/
                    else monoactif=monoactif*coeffTpsPartiel2;
                    etiqMono2:
                    end;
                    else monoactif=0;
                    monoactif=round(monoactif);


 			/*** Majoration pour personnes � charges ***/

/*NB: aucune majoration pour personne � charge n est accord�e si les seules personnes b�n�ficiant de la PPE sont des personnes � charge*/

                    /** Calcul du nombre de personnes � charge ouvrant droit � majoration **/
                    /*Il s agit de retrancher au nombre de PAC le nombre de PAC ayant b�n�ficier de la PPE et/ou le nombre de PAC ayant des revenus trop �lev�s
					pour ouvrir droit � une majoration*/
                    nbPACexclusif   =   F+R+J+N;
                    nbPACalternee   =   H+P;
                    nbPACmajo       =   max( nbPACexclusif + nbPACalternee - 
                                        ((revPAC1>&ppe_indiv1.)+(revPAC2>&ppe_indiv1.)+(revPAC5>&ppe_indiv1.) ),0);

                    if nbPACmajo>0 then do;
                        if nbPACexclusif>=nbPACmajo then do;
                            nbPACexclusif=nbPACmajo;
                            nbPACalternee=0;
                         end;
                         else if nbPACexclusif<nbPACmajo then do;
                            nbPACalternee=nbPACmajo-nbPACexclusif;
                         end;
                      end;
                      else do;
                        nbPACexclusif=0;
                        nbPACalternee=0;
                    end;

                    nbEnfPPE=nbPACexclusif+nbPACalternee;

                    /** Cas des foyers de personnes mari�es (biactifs ou non) ou c�libataires, divorc�s, veufs n �levant pas seuls leurs enfants � charge **/
                    if  (matn in (1,6) and (revDEC>=&ppe_indiv1. or revCONJ>=&ppe_indiv1.) ) or
                        (matn in (2,3) and revDEC>=&ppe_indiv1. and zTn=0) or
                        (matn in (4)   and revDEC>=&ppe_indiv1. ) 
                      then do;
                        if  (revDEC>=&ppe_indiv1. and &ppe_indiv1.<=baseDEC<=&ppe_indiv3.) or
                            (revCONJ>=&ppe_indiv1. and &ppe_indiv1.<=baseCONJ<=&ppe_indiv3.)
                        then majoPAC=&ppe_coupleENF*(nbPACexclusif+nbPACalternee/2);
                        /*Couple monoactif avec activit� sup�rieure � &ppe_indiv3*/
                        else if (   (matn in (1,6) and revDEC>=&ppe_indiv1. and revCONJvrai<&ppe_indiv1.)  
                                 or (matn in (1,6) and revDECvrai<&ppe_indiv1. and revCONJ>=&ppe_indiv1.) ) and
                                (&ppe_indiv3.<=baseDEC<=&ppe_indiv5. OR &ppe_indiv3.<=baseCONJ<=&ppe_indiv5.)
                        then majoPAC=&ppe_coupleENF.*((nbPACexclusif>=1)+(nbPACexclusif=0 and nbPACalternee>=1)/2);
                        else majoPAC=0;
                    end;

                    /** Cas des c�libataires, divorc�s, veufs �levant seuls leurs enfants � charge (case T coch�e) **/
                    /*Attention pour les veufs : seuls ceux qui n ont pas coch� la case L (en plus de la case T)*/
                    else if (matn in (2,3) and revDEC>=&ppe_indiv1. and ztn=1) or
                            (matn in (4)   and revDEC>=&ppe_indiv1. and ztn=1)
                    then do;
                        if &ppe_indiv1.<=baseDEC<=&ppe_indiv3. then do;
                            if nbPACexclusif>=1 then
                            majoPAC=&ppe_isoleENF.+&ppe_coupleENF.*(max(nbPACexclusif-1,0)+nbPACalternee/2);
                            else 
                            majoPAC=&ppe_isoleENF.*min(nbPACalternee,2)/2+&ppe_coupleENF.*max(nbPACalternee-2,0)/2;
                        end;
                        else if &ppe_indiv3.<baseDEC<=&ppe_indiv5. then 
                            majoPAC=&ppe_isoleENF.*((nbPACexclusif>=1)+(nbPACexclusif=0 and nbPACalternee>=1)/2);
                        else
                            majoPAC=0;
                    end;
                    else majoPAC=0;


			/*** PPE totale et seuil de paiement ***/
            PPE= PPE + monoactif + majoPAC;

            if PPE<&ppe_seuil. then ppe=0;

            ETIQfinPPE:
        label PPE = "Montant de PPE attribu� au foyer fiscal avant imputation du RSA activit�";
    %end ;


		/*** Imputation du RSA activit� sur le montant de PPE du foyer fiscal ***/

        RSA_tot=0 ;
        ppe_ap_imputRSA = 0; /*on ne calcule pas le RSA � cette �tape*/

        label PPE_ap_imputRSA = "Montant de PPE restitu� aux foyers fiscaux apr�s imputation du RSA activit�";

			/*** Cr�dit d imp�ts acompte avec bar�misation ***/
        crPFO      =   PFO;        
        label crPFO    =   "Cr�dit d impot - Acompte de PFO d�j� vers�" ; 

			/*** Cr�dit d impots directive �pargne ***/
        crEpargne = _2bg ; 
        label crEpargne    =   "Cr�dit d impot - directive �pargne" ;

			/*** Pr�l�vement lib�ratoire de 45% sur les plus-values de cession des non-r�sidents ***/ 
        crCessionNonRes = _3VV ; 
        label crCessionNonRes    =   "Cr�dit d impot - pr�l�vement lib�ratoire sur les plus-values de cession des non-r�sidents" ; 

			/*** Cr�dit d impots Corse ***/
        crCorse = _8TS ; 
        label crCorse    =   "Cr�dit d impot - Corse" ; 

			/*** Cr�dit d impots pr�l�vement forfaitaire Mayotte ***/
        crMayotte = _8UV ; 
        label crMayotte   =   "Cr�dit d impot - Mayotte" ; 


/*************************************************************************************************************************************************************/
/*		d. Ensemble des cr�dits d'impots restituables et non restituables										 			             			         */
/*************************************************************************************************************************************************************/

    credit      = crRecherche + crCICE + crElusLocaux + crFamille + crApprentissage + crAgriBio 
                + crProspection + crFormationChef + crMetiersArt 
                + crCongeAgriculteur + crMaitreRestau  
                + crInteressement + crAssuVie + crDvtDurable + crGrosEquipement 
                + crDroitBail + crGardeEnfant + crEtudiant + crSalarieDomicile 
                + crInteretEmprunt + crPrimesAssurance + crAUtoEnt + crTravTech + crQualEnv + crEpargne
                %if &switch_ppe.=1 %then %do ; + ppe  %end ;
                + crPFO
                + crCotisationsSyndicales + crCessionNonRes + CrCorse + crMayotte; 

    label credit =  "Montant total des cr�dits d impot dt b�n�ficie le foyer fiscal" ;


/*************************************************************************************************************************************************************/
/*		e. Plafonnement de l ensemble des avantages fiscaux (RI et CI) � 10 000 � + 0% du revenu imposable					            			         */
/*************************************************************************************************************************************************************/

    VarPlaf1     =  redAssuranceForet + redSalarieDomicile + ReducScellier + ReducInvMeuNonPro + redTourisme +
                    RedRestauImmo + redInvestForestier +
                    redFCPI + redFIP + redFIPC + redFipDom+ redInvestLocDuflot  + redPME + 
                    redRestauration + redprotecpat +

                    /*Ensemble des cr�dits d imp�t*/
                    crSalarieDomicile + crGardeEnfant + crDvtDurable + crInteretEmprunt + crPrimesAssurance

                    /*Dispositifs Robien ou Borloo Neuf*/
                    + _4by
                    ;

    VarPlaf2 = redSOFICA + redDOMLogement + redDOMEntreprise + redDOMsocial ; 
    DiffAvFisc1  =   VarPlaf1 - (&niche_plaf_fixe. + &niche_plaf_taux. * RICALC1); 

    if VarPlaf2 >0 then do ; 
            DiffAvFisc2  =   min(VarPlaf1, &niche_plaf_fixe. + &niche_plaf_taux. * RICALC1)
                                + VarPlaf2 - (&niche_plaf_fixe. + &niche_plaf_majo. + &niche_plaf_taux. * RICALC1); 
            DiffAvFisc = DiffAvFisc1+ DiffAvFisc2 ;  
    end ; 
    else do DiffAvFisc = DiffAvFisc1; end; 


/*************************************************************************************************************************************************************/
/*		f. Imputation des r�ductions et cr�dits d'impot															 			             			         */
/*************************************************************************************************************************************************************/

			/*** R�ductions d imp�t ***/ 
        /*Application aux r�ductions d�imp�t du plafonnement global des avantages fiscaux*/ 
        If DiffAvFisc > 0 then Reduction = max(Reduction - DiffAvFisc,0);

        /*Imputation sur l�IR de l ensemble des r�ductions d imp�t*/
        DSE =   MAX(DSE_bareme - Reduction,0);
        Reduction_imputee = DSE_bareme - DSE ;

        /*Calcul de la part imputee de chaque RI*/ 
        IR_RI   = DSE_bareme ;

        %part_imputee(IR_RI,redAssuranceForet) ;
        %part_imputee(IR_RI,redDONSoeuvres1) ;
        %part_imputee(IR_RI,redSalarieDomicile) ;
        %part_imputee(IR_RI,redInteretsAgri) ;
        %part_imputee(IR_RI,redDefenseIncendie) ;
        %part_imputee(IR_RI,redFipDom) ; 
        %part_imputee(IR_RI,redFIPC) ;
        %part_imputee(IR_RI,redSOFICA) ;
        %part_imputee(IR_RI,RedRestauImmo) ;
        %part_imputee(IR_RI,redRepriseSociete) ;
        %part_imputee(IR_RI,redPrestaCompens) ;  
        %part_imputee(IR_RI,redDepensesDependance) ;
        %part_imputee(IR_RI,redRentesSurvie) ;
        %part_imputee(IR_RI,redFCPI) ;
        %part_imputee(IR_RI,redFIP) ;
        %part_imputee(IR_RI,redRestauration) ;
        %part_imputee(IR_RI,redDOMLogement) ;
        %part_imputee(IR_RI,redCreateurEntreprise) ;
        %part_imputee(IR_RI,redCGA) ;
        %part_imputee(IR_RI,redFraisScolarisation) ;
        %part_imputee(IR_RI,redDONSoeuvres2) ;
        %part_imputee(IR_RI,redInvestLocDuflot) ;
        %part_imputee(IR_RI,redPME) ;
        %part_imputee(IR_RI,redInvestForestier) ;
        %part_imputee(IR_RI,redTourisme) ;
        %part_imputee(IR_RI,ReducScellier) ;
        %part_imputee(IR_RI,ReducInvMeuNonPro) ;
        %part_imputee(IR_RI,redprotecpat) ;
        %part_imputee(IR_RI,redDOMsocial) ;
        %part_imputee(IR_RI,redDomEntreprise) ;
        %part_imputee(IR_RI,redIR) ; 


			/*** Cr�dits d imp�t non restituables ***/ 

        /*Contribution Exceptionnelle sur les hauts revenus*/
        CEHR2 = &CEHR_taux1.* min((&CEHR_seuil2.-&CEHR_seuil1.)*((matn in (2 3 4))+ 2*(matn in (1 6))),
                                  max(rfr_recalc2-&CEHR_seuil1.*((matn in (2 3 4))+ 2*(matn in (1 6))),0))

             + &CEHR_taux2. * max(rfr_recalc2-&CEHR_seuil2.*((matn in (2 3 4))+ 2*(matn in (1 6))),0) ;


        IRP2 = MAX(MAX(DSE + PVproportionnel +CEHR2- cnrBiensCulturels-redMecenat,0)+_8TP+_8TF-cnrSousTotal,0);
                
			/*** Cr�dits d imp�t restituables ***/

/*NB : Application du plafonnement de l avantage fiscal - Apr�s premi�re imputation sur les r�ductions*/
        credit_av_plaf = credit ; 
            if (Reduction - DiffAvFisc < 0) then credit = max(credit - (DiffAvFisc - Reduction), 0);


/*************************************************************************************************************************************************************/
/*		g. Calcul de l impot sur le revenu net																	 			             			         */
/*************************************************************************************************************************************************************/

        IR_ap_CI = IRP2 - credit;
        credit_impute = IRP2-max(IR_ap_CI,0) ;
        credit_restit = IR_ap_CI*(IR_ap_CI<0) ;

        IMPOT1 = IR_ap_CI;

        /*Seuil minimum de perception avant restitutions (art.1657 1bis CGI)*/
        if IMPOT1 > 0 & IRP2 < &seuil_perc_avt_restit.    then Impot0 = 0;
        /*Seuil minimum de perception apr�s restitutions (PF/LI/1�P/T1/C)*/
        else if IMPOT1 > 0 & IMPOT1 < &seuil_perc_apt_restit.     then Impot0=0;
        /*Seuil minimum de restitution*/
        else if -&seuil_restit. < Impot1 < 0             then Impot0=0;

        else impot0 = impot1 ;

        label   DSE                     =     "Imp�t apr�s r�ductions d impot (en �)"
                IRP2                     =     "Imp�t avant imputations (des r�ductions et cr�dits d impot et du plafonnement des avantages fiscaux) (en �)"
                IR_ap_CI                =     "Imp�t d� (y.c. imputation du RSA) (en �)"
                IMPOT0                   =     "Imp�t d� mis en recouvrement(y.c. imputation du RSA) (en �)" ; 

        impot=impot0 ;
        impot_brut  = max(impot0, 0);
        degrevement = -min(impot0, 0);
        ir_hors_ppe = impot + PPE_ap_imputRSA ;
        ppe_inpute  = min(max(ir_hors_ppe,0), PPE_ap_imputRSA) ;
        ppe_restit  = PPE_ap_imputRSA - ppe_inpute ;
        autre_degr  = degrevement - ppe_restit ; 

        natimp_recalc = 0 ;
/*      Modalit�    Signification
        0         Non imposable ou non mis en recouvrement
        1         Impos�s
        11        Restituable partiel
        21        Restituable total
        70        D�grevable partiel
        71        D�grevable total
        81        Restituable partiel suite � d�gr�vement d�office
        91        Restituable total suite � d�gr�vement d�office
*/
        if IR_ap_CI >= &seuil_perc_apt_restit. then natimp_recalc = 1 ;
        if IRP2 > 0 & IRP2 < credit        then natimp_recalc = 11 ;
        if IRP2 = 0 & credit > 0          then natimp_recalc = 21 ;

        imposable0       =   natimp_recalc in (1, 11) ;
        label imposable0 =   "0/1 : foyer imposable ou non � l IR (impot0)" ;

        impose0       =   impot0 > 0 ;
        label impose0 =   "0/1 : foyer impos� ou non � l IR (impot0 > 0)" ;

        impose_cehr       =   cehr2 > 0 ;
        label impose_cehr =   "0/1 : foyer impos� ou non � la CEHR" ;

        benef_PPE = PPE_ap_imputRSA>0 ;
        label benef_PPE =   "0/1 : foyer b�n�ficie ou non de la PPE" ;



/*************************************************************************************************************************************************************/
/*				8 - Pr�l�vement lib�ratoire                                																					 */
/*************************************************************************************************************************************************************/
prel_liberatoire=PFL + PFO  ;	/*on r�cup�re le PFL et le PFO qui ne sont pas de l'imp�t � proprement parler*/

run;

%mend ; %calcul_impot (annee=&asuiv2.);


proc datasets library=work; delete foyer&acour.rev&asuiv2. ; run; quit;


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/
