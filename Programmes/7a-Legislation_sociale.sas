

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 7a                                         			     			      */
/*                     										Param�tres de la l�gislation sociale															  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* L'ERFS ne comprend � l'origine que les revenus imposables. Les montants de CSG, CRDS et cotisations sociales sont recalcul�s de mani�re � pouvoir passer du*/
/* revenu imposable recueilli au revenu net intervenant dans le calcul du revenu disponible ou de certaines prestations. 									  */ 
/*																																							  */
/* Dans un premier temps, le programme 6 applique la l�gislation 2013 sur les revenus de l'ERFS (y compris vieillis 2016 et 2017) afin d'obtenir les revenus  */
/* bruts. Ces derniers sont inchang�s en cas de r�forme des taux, ce qui suppose notamment qu'une hausse de cotisation sociale ou de CSG ne sera jamais capt�e*/
/* par l'employeur.																																			  */
/* Dans un second temps (programme 7a, 8a et 9a), les montants de cotisations sont recalcul�s � partir des revenus bruts d�finis dans ce programme. Ils		  */
/* peuvent donc diff�rer des montants d�finis dans ce programme si une nouvelle l�gislation est appliqu�e. Un nouveau revenu imposable est d�fini et un		  */
/* nouveau revenu net est calcul�.																															  */ 	
/*																																							  */
/* Les revenus concern�s sont les suivant :  																												  */
/* 		- Retraites (CSG, CRDS et Casa)   																												   	  */
/* 		- Ch�mage (CSG et CRDS)																																  */
/*		- Salaires du priv� (CSG, CRDS et cotisations sociales)																								  */
/*		- Revenus des ind�pendants (CSG, CRDS et cotisations sociales)																						  */
/*																																							  */
/* Ce programme d�finit les variables n�cessaires � la reconstruction de la l�gislation sociale pour les ann�es 2014,2015,2016 et 2017.                       */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       									I. Taux de CSG, CRDS et cotisations sociales                 									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* On d�finit les variables n�cessaires � la reconstruction de la l�gislation sociale de :							                 						  */
/*		-asuiv. : 2014																																		  */
/*		-asuiv2. : 2015																																		  */
/*		-asuiv3. : 2016																																		  */
/*		-asuiv4. : 2017																																		  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Montant du Smic et inflation							                 												     				  */
/**************************************************************************************************************************************************************/

%let smic_net=1120.82;   			/*nombre d'heures mensuelles pour un temps plein conventionnel : 151.666*/
%let smic_brut=1430.22; 			/*correspond au SMIC pour l'ann�e de l'ERFS*/

%let smic_hor_brut&asuiv.=9.53; 	
%let smic_hor_brut&asuiv2.=9.61; 	
%let smic_hor_brut&asuiv3.=9.67; 	
%let smic_hor_brut&asuiv4.=9.76; 	

/*Coefficients de revalorisation des prestations*/
%let tx_revalo=1.003 ; 				/*revalorisation des prestations au 1er avril*/
%let tx_revalo_plaf=1.0 ; 			/*revalorisation des plafonds au 1er janvier : inflation hors tabac N-2 (voir circulaire DSS/SD2B/2016/396 pour 2017)*/
%let revalo_irl&asuiv3.=1.0 ;  		/*�volution de l'IRL au T2 n-1 : 0% au t2 2016*/
%let revalo_irl&asuiv4.=1.0075 ; 	/*�volution de l'IRL en glissement annuel au T2 2017*/


/**************************************************************************************************************************************************************/
/*				2- Taux de CRDS						 					                												     				  */
/**************************************************************************************************************************************************************/

/*Taux de CRDS*/
%let tx_crds&asuiv2.=0.005;
%let tx_crds&asuiv3.=0.005;
%let tx_crds&asuiv4.=0.005;


/**************************************************************************************************************************************************************/
/*				3- Taux de CSG sur les retraites et les pensions, et Casa (RST)            												     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* La tranche 1 correspond aux retrait�s exon�r�s, la tranche 2 au taux r�duit et la tranche 3 au taux plein    						    				  */
/**************************************************************************************************************************************************************/

/*Taux de CSG d�ductible */
%let tx_csgd1_rst&asuiv2.=0;
%let tx_csgd2_rst&asuiv2.=0.038;
%let tx_csgd3_rst&asuiv2.=0.042;

%let tx_csgd1_rst&asuiv3.=0;
%let tx_csgd2_rst&asuiv3.=0.038;
%let tx_csgd3_rst&asuiv3.=0.042;

%let tx_csgd1_rst&asuiv4.=0;
%let tx_csgd2_rst&asuiv4.=0.038;
%let tx_csgd3_rst&asuiv4.=0.042;

/*Taux de CSG non d�ductible/imposable*/
%let tx_csgi1_rst&asuiv2.=0;
%let tx_csgi2_rst&asuiv2.=0;
%let tx_csgi3_rst&asuiv2.=0.024;

%let tx_csgi1_rst&asuiv3.=0;
%let tx_csgi2_rst&asuiv3.=0;
%let tx_csgi3_rst&asuiv3.=0.024;

%let tx_csgi1_rst&asuiv4.=0;
%let tx_csgi2_rst&asuiv4.=0;
%let tx_csgi3_rst&asuiv4.=0.024;

/*Taux de Contribution additionnelle de solidarit� pour l'autonomie*/
%let tx_casa&asuiv2.=0.003;
%let tx_casa&asuiv3.=0.003;
%let tx_casa&asuiv4.=0.003;

/*Limite de RFR pour l'exon�ration de CSG*/
%let seuil_exo_csg&asuiv.=10633; 		/*on prend l'ann�e d'imposition correspondant aux revenus ERFS car on utilise le statut d'imposition 2014 comme proxy*/
%let seuil_exo_csg_demipart&asuiv.=2839;

%let seuil_exo_csg&asuiv4.=%sysfunc(round(10996*&tx_revalo_plaf.));
%let seuil_exo_csg_demipart&asuiv4.=%sysfunc(round(2936*&tx_revalo_plaf.));

/*Limite de RFR pour le taux r�duit de CSG*/
/*A partir de 2015, on passe d'un crit�re d'imposabilit� � un crit�re de RFR. 
En 2015, c'est la premi�re ann�e o� on met en place le crit�re de RFR par rapport au RFR 2013 (celui de l'ERFS)*/ 

%let seuil_tx_red&asuiv.=13900; 
%let seuil_tx_red_demipart&asuiv.=3711;

%let seuil_tx_red&asuiv4.=%sysfunc(round(14375*&tx_revalo_plaf.));
%let seuil_tx_red_demipart&asuiv4.=%sysfunc(round(3838*&tx_revalo_plaf.));


/**************************************************************************************************************************************************************/
/*				4- Taux de CSG ch�mage et pr�retraites (CHO)				            												     				  */
/**************************************************************************************************************************************************************/

/*Assiette de calcul de la CSG*/
%let ass_csg_cho&asuiv2.=0.9825;
%let ass_csg_cho&asuiv3.=0.9825;
%let ass_csg_cho&asuiv4.=0.9825;

/**************************************************************************************************************************************************************/
/* La tranche 1 correspond aux ch�meurs exon�r�s, la tranche 2 au taux r�duit et la tranche 3 au taux plein, la tranche 4 aux pr�retraites    				  */
/**************************************************************************************************************************************************************/

/*Taux de CSG d�ductible */
%let tx_csgd1_cho&asuiv2.=0;
%let tx_csgd2_cho&asuiv2.=0.038;
%let tx_csgd3_cho&asuiv2.=0.038;
%let tx_csgd4_cho&asuiv2.=0.051;

%let tx_csgd1_cho&asuiv3.=0;
%let tx_csgd2_cho&asuiv3.=0.038;
%let tx_csgd3_cho&asuiv3.=0.038;
%let tx_csgd4_cho&asuiv3.=0.051;

%let tx_csgd1_cho&asuiv4.=0;
%let tx_csgd2_cho&asuiv4.=0.038;
%let tx_csgd3_cho&asuiv4.=0.038;
%let tx_csgd4_cho&asuiv4.=0.051;

/*Taux de CSG non d�ductible/imposable*/
%let tx_csgi1_cho&asuiv2.=0;
%let tx_csgi2_cho&asuiv2.=0;
%let tx_csgi3_cho&asuiv2.=0.024;

%let tx_csgi1_cho&asuiv3.=0;
%let tx_csgi2_cho&asuiv3.=0;
%let tx_csgi3_cho&asuiv3.=0.024;

%let tx_csgi1_cho&asuiv4.=0;
%let tx_csgi2_cho&asuiv4.=0;
%let tx_csgi3_cho&asuiv4.=0.024;

/*Allocation journali�re minimale en moyenne annuelle : composante du calcul de l'ARE, d�cr�t�e par l'Unedic tous les 1er juillet*/
/*Utilis�e pour le calcul des cotisations sociales sur les revenus du ch�mage*/
%let ajm&asuiv2.=28.67;
%let ajm&asuiv3.=28.67;
%let ajm&asuiv4.=%sysevalf(28.67*6/12+28.86*6/12);		/*en moyenne annuelle*/ 

/*Le taux de cotisation pour les retraites compl�mentaires d�pend du salaire journalier de r�f�rence : pour son calcul on utilise le taux de remplacement 
minimum (valable si le salaire journalier de r�f�rence (SRJ) est sup�rieur � 1.5 smic)*/ 
%let tx_remplacement&asuiv2.=0.57;
%let tx_remplacement&asuiv3.=0.57;
%let tx_remplacement&asuiv4.=0.57;

/*Cotisation retraite compl�mentaire du ch�mage total*/
%let tx_css_cho&asuiv2.=0.03;
%let tx_css_cho&asuiv3.=0.03;
%let tx_css_cho&asuiv4.=0.03;


/**************************************************************************************************************************************************************/
/*				5- Taux de CSG, CRDS et cotisations sociales sur les salaires           												     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Plafond de la s�curit� sociale (en �/mois)																			 		                      */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Le plafond de la s�curit� sociale (PSS) est d�fini ici en � par mois. Il est revaloris� chaque ann�e N en fonction de l'�volution du SMPT nominal pour     */
/* l'ann�e N-1, qui figure dans le RESF du PLF pour N. Si la pr�vision du RESF diff�re de l'�volution constat�e du SMPT, on applique un correctif.			  */
/*																																							  */
/* La pr�vion du SMPT 2014 du RESF 2015 �tait de 1,7 %, contre 1,6 % finalement observ�. On applique donc un correctif de -0,1 pour l'ann�e 2015.	 		  */
/* En 2016, la pr�vision du SMPT 2015 dans le RESF 2016 s'�levait � 1,6 %. Le constat� en 2015 est de 1,6 % : on n'applique pas de correctif pour l'ann�e 2016*/ 
/* L'�volution pr�vue du SPMT 2016 est de 1,6 % (RESF 2017, p. 47) : la r�valorisation pr�vue pour 2017 sera donc de 1,6 % (pas de correctif pour 2016)       */
/* Voir aussi : p. 51 du rapport 2016 de la CCSS																											  */
/**************************************************************************************************************************************************************/

%let PSS&asuiv.=3129 ;
%let PSS&asuiv2.=3170 ; 
%let PSS&asuiv3.=3218 ; 
%let PSS&asuiv4.=3269 ;


/**************************************************************************************************************************************************************/
/*		b. Cotisations sociales																									 		                      */
/**************************************************************************************************************************************************************/

	/** Bornes inf�rieure et sup�rieure des tranches de cotisation **/

%macro plafonds(annee= );
    %global  binf_css_nc1 bsup_css_nc1 binf_css_nc2 bsup_css_nc2 binf_css_nc3 bsup_css_nc3 binf_css_nc4 bsup_css_nc4
             binf_css_c1 bsup_css_c1 binf_css_c2 bsup_css_c2 binf_css_c3 bsup_css_c3 binf_css_c4 bsup_css_c4;

	/*Non cadres*/
    %let binf_css_nc1=0;
    %let bsup_css_nc1=%eval(&&PSS&annee.);

    %let binf_css_nc2=%eval(&&PSS&annee.);
    %let bsup_css_nc2=%eval(3*&&PSS&annee.);

    %let binf_css_nc3=%eval(3*&&PSS&annee.);
    %let bsup_css_nc3=%eval(4*&&PSS&annee.);

    %let binf_css_nc4=%eval(4*&&PSS&annee.);
    %let bsup_css_nc4=%eval(100*&&PSS&annee.);

    /*Cadres*/
    %let binf_css_c1=0;
    %let bsup_css_c1=%eval(&&PSS&annee.);

    %let binf_css_c2=%eval(&&PSS&annee.);
    %let bsup_css_c2=%eval(4*&&PSS&annee.);

    %let binf_css_c3=%eval(4*&&PSS&annee.);
    %let bsup_css_c3=%eval(8*&&PSS&annee.);

    %let binf_css_c4=%eval(8*&&PSS&annee.);
    %let bsup_css_c4=%eval(100*&&PSS&annee.);

%mend;


	/** Taux **/

	/*D�tails g�n�raux */

/*Maladie, maternit�, d�c�s, invalidit�*/
/*Assiette : totalit� salaire*/
%let tx_css_mmdi&asuiv2.=0.0075; 
%let tx_csp_mmdi&asuiv2.=0.1280;

%let tx_css_mmdi&asuiv3.=0.0075; 
%let tx_csp_mmdi&asuiv3.=0.1284;

%let tx_css_mmdi&asuiv4.=0.0075; 
%let tx_csp_mmdi&asuiv4.=0.1289;

/*Solidarit� autonomie*/ 
/*Assiette : totalit� salaire*/
%let tx_csp_solauto&asuiv2.=0.003;
%let tx_csp_solauto&asuiv3.=0.003;
%let tx_csp_solauto&asuiv4.=0.003;

/*Vieillesse*/
/*Assiette : entre 0 et 1 PSS*/ 
%let tx_css_vieil&asuiv2.=0.0685;
%let tx_csp_vieil&asuiv2.=0.0850;

%let tx_css_vieil&asuiv3.=0.0690;
%let tx_csp_vieil&asuiv3.=0.0855;

%let tx_css_vieil&asuiv4.=0.0690;
%let tx_csp_vieil&asuiv4.=0.0855;

/*Assiette : toute l'assiette*/
%let tx_css_vieil_tot&asuiv2. = 0.003; 
%let tx_csp_vieil_tot&asuiv2. = 0.018;

%let tx_css_vieil_tot&asuiv3. = 0.0035; 
%let tx_csp_vieil_tot&asuiv3. = 0.0185;

%let tx_css_vieil_tot&asuiv4. = 0.004; 
%let tx_csp_vieil_tot&asuiv4. = 0.019;

/*Allocations familliales (AF)*/
/*Assiette : totalit� salaire*/
%let tx_csp_AF&asuiv2.=0.0525;
%let tx_csp_AF&asuiv3.=0.0525;
%let tx_csp_AF&asuiv4.=0.0525;
%let tx_csp_AF_bas_salaires&asuiv2.=0.345; 	/*taux r�duit de cotisations AF jusqu'� 1,6 Smic*/
%let tx_csp_AF_bas_salaires&asuiv3.=0.345; 	/*taux r�duit de cotisations AF jusqu'� 3,5 Smic*/
%let tx_csp_AF_bas_salaires&asuiv4.=0.345; 	/*taux r�duit de cotisations AF jusqu'� 3,5 Smic*/
%let plaf_af_bas_salaires&asuiv2.=1.6;
%let plaf_af_bas_salaires&asuiv3.=3.5;
%let plaf_af_bas_salaires&asuiv4.=3.5;

/*Accidents du travail : le taux retenu est un taux moyen car il est variable selon l'entreprise et la branche*/
/*Assiette : totalit� salaire*/
%let tx_csp_ATMP&asuiv2.=0.0244; 
%let tx_csp_ATMP&asuiv3.=0.0238; 
%let tx_csp_ATMP&asuiv4.=0.0233;
 

/*ASSEDIC*/
/*Assiette : entre 0 et 4 PSS*/
%let tx_css_assedic&asuiv2.=0.024; 
%let tx_csp_assedic&asuiv2.=0.04; 

%let tx_css_assedic&asuiv3.=0.024; 
%let tx_csp_assedic&asuiv3.=0.04; 

%let tx_css_assedic&asuiv4.=0.024; 
%let tx_csp_assedic&asuiv4.=0.04; 

/*Fonds de garantie des salaires*/
/*Assiette : entre 0 et 4 PSS*/
%let tx_csp_AGS&asuiv2.=0.003;
%let tx_csp_AGS&asuiv3.=0.0025;
%let tx_csp_AGS&asuiv4.=0.0025;

/*Fonds national d'aide au logement*/
/*Assiette : entre 0 et 1 PSS toutes entreprises*/
/*A partir de 2015, on distingue petites et grandes entreprises, les taux sont renseign�s dans le code plus bas (pas de taux pour toutes entreprises)*/ 
%let tx_csp_fnal&asuiv2.=0;		
%let tx_csp_fnal&asuiv3.=0; 
%let tx_csp_fnal&asuiv4.=0; 

/*Taxe d'apprentissage*/
/*Assiette : totalit� salaire*/
%let tx_csp_tap&asuiv2.=0.0068;
%let tx_csp_tap&asuiv3.=0.0068;
%let tx_csp_tap&asuiv4.=0.0068;

/*Autres cotisations patronales fonction de la taille de l'entreprise : formation professionnelle (FP), FNAL + 20 salari�s et construction*/
/*Assiette : totalit� salaire*/
/*R�forme en 2015*/
/*Cr�ation de la tranche entre 0 et 1 PSS pour les entreprises de moins de 10 salari�s*/
%let tx_csp_m10sal1&asuiv2.=0.00676; 	/*Fnal : 0.1 FP : 0.55 ;syndic 0.016 ;p�nibilit� base 0.01*/						/*entre 0 et 1 PSS*/
%let tx_csp_m10sal2&asuiv2.=0.00576; 	/*Fnal : 0   FP : 0.55 ;syndic 0.016 ;p�nibilit� base 0.01*/						/*au-del� de 1 PSS*/
%let tx_csp_10a20sal1&asuiv2.=0.01126; 	/*Fnal : 0.1 FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01*/ 						/*entre 0 et 1 PSS*/
%let tx_csp_10a20sal2&asuiv2.=0.01026; 	/*Fnal : 0   FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01*/ 						/*au-del� de 1 PSS*/
%let tx_csp_p20sal&asuiv2.=0.01976; 	/*Fnal : 0.5 FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01; construction : 0.45*/	/*ensemble du salaire*/ 

%let tx_csp_m10sal1&asuiv3.=0.00676; 	/*Fnal : 0.1 FP : 0.55 ;syndic 0.016 ;p�nibilit� base 0.01*/						/*entre 0 et 1 PSS*/
%let tx_csp_m10sal2&asuiv3.=0.00576; 	/*Fnal : 0   FP : 0.55 ;syndic 0.016 ;p�nibilit� base 0.01*/						/*au-del� de 1 PSS*/
%let tx_csp_10a20sal1&asuiv3.=0.01126; 	/*Fnal : 0.1 FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01*/ 						/*entre 0 et 1 PSS*/
%let tx_csp_10a20sal2&asuiv3.=0.01026; 	/*Fnal : 0   FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01*/ 						/*au-del� de 1 PSS*/
%let tx_csp_p20sal&asuiv3.=0.01976; 	/*Fnal : 0.5 FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01; construction : 0.45*/	/*ensemble du salaire*/ 

%let tx_csp_m10sal1&asuiv4.=0.00676; 	/*Fnal : 0.1 FP : 0.55 ;syndic 0.016 ;p�nibilit� base 0.01*/						/*entre 0 et 1 PSS*/
%let tx_csp_m10sal2&asuiv4.=0.00576; 	/*Fnal : 0   FP : 0.55 ;syndic 0.016 ;p�nibilit� base 0.01*/						/*au-del� de 1 PSS*/
%let tx_csp_10a20sal1&asuiv4.=0.01126; 	/*Fnal : 0.1 FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01*/ 						/*entre 0 et 1 PSS*/
%let tx_csp_10a20sal2&asuiv4.=0.01026; 	/*Fnal : 0   FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01*/ 						/*au-del� de 1 PSS*/
%let tx_csp_p20sal&asuiv4.=0.01976; 	/*Fnal : 0.5 FP : 1.00 ;syndic 0.016 ;p�nibilit� base 0.01; construction : 0.45*/	/*ensemble du salaire*/ 


	/*D�tails non cadres*/

/*ARRCO : retraite compl�mentaire*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_ret1&asuiv2.=0.031;
%let tx_csp_ret1&asuiv2.=0.0465;

%let tx_css_ret1&asuiv3.=0.031;
%let tx_csp_ret1&asuiv3.=0.0465;

%let tx_css_ret1&asuiv4.=0.031;
%let tx_csp_ret1&asuiv4.=0.0465;

/*Assiette : entre 1 et 3 PSS*/
%let tx_css_ret2&asuiv2.=0.081;
%let tx_csp_ret2&asuiv2.=0.1215;

%let tx_css_ret2&asuiv3.=0.081;
%let tx_csp_ret2&asuiv3.=0.1215;

%let tx_css_ret2&asuiv4.=0.081;
%let tx_csp_ret2&asuiv4.=0.1215;

/*AGFF*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_agff_nc1&asuiv2.=0.008; 
%let tx_csp_agff_nc1&asuiv2.=0.012; 

%let tx_css_agff_nc1&asuiv3.=0.008; 
%let tx_csp_agff_nc1&asuiv3.=0.012; 

%let tx_css_agff_nc1&asuiv4.=0.008; 
%let tx_csp_agff_nc1&asuiv4.=0.012; 


/*Assiette : entre 1 et 3 PSS*/
%let tx_css_agff_nc2&asuiv2.=0.009; 
%let tx_csp_agff_nc2&asuiv2.=0.013; 

%let tx_css_agff_nc2&asuiv3.=0.009; 
%let tx_csp_agff_nc2&asuiv3.=0.013; 

%let tx_css_agff_nc2&asuiv4.=0.009; 
%let tx_csp_agff_nc2&asuiv4.=0.013; 


	/*D�tails cadres*/

/*Retraite compl�mentaire*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_retA&asuiv2.=0.031; 
%let tx_csp_retA&asuiv2.=0.0465;

%let tx_css_retA&asuiv3.=0.031; 
%let tx_csp_retA&asuiv3.=0.0465;

%let tx_css_retA&asuiv4.=0.031; 
%let tx_csp_retA&asuiv4.=0.0465;

/*Assiette : entre 1 et 4 PSS*/
%let tx_css_retB&asuiv2.=0.078;
%let tx_csp_retB&asuiv2.=0.1275;

%let tx_css_retB&asuiv3.=0.078;
%let tx_csp_retB&asuiv3.=0.1275;

%let tx_css_retB&asuiv4.=0.078;
%let tx_csp_retB&asuiv4.=0.1275;

/*Assiette : entre 4 et 8 PSS*/
%let tx_css_retC&asuiv2.=0.078;
%let tx_csp_retC&asuiv2.=0.1275;

%let tx_css_retC&asuiv3.=0.078;
%let tx_csp_retC&asuiv3.=0.1275;

%let tx_css_retC&asuiv4.=0.078;
%let tx_csp_retC&asuiv4.=0.1275;

/*Contribution exceptionnelle et temporaire*/
/*Assiette : entre 0 et 8 PSS*/
%let tx_css_cet&asuiv2.=0.0013; 
%let tx_csp_cet&asuiv2.=0.0022;

%let tx_css_cet&asuiv3.=0.0013; 
%let tx_csp_cet&asuiv3.=0.0022;

%let tx_css_cet&asuiv4.=0.0013; 
%let tx_csp_cet&asuiv4.=0.0022;


/*D�c�s*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_csp_deces&asuiv2.=0.015;
%let tx_csp_deces&asuiv3.=0.015;
%let tx_csp_deces&asuiv4.=0.015;

/*AGFF*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_agff_A&asuiv2.=0.008; 
%let tx_csp_agff_A&asuiv2.=0.012;

%let tx_css_agff_A&asuiv3.=0.008; 
%let tx_csp_agff_A&asuiv3.=0.012;

%let tx_css_agff_A&asuiv4.=0.008; 
%let tx_csp_agff_A&asuiv4.=0.012;

/*Assiette : entre 1 et 4 PSS*/
%let tx_css_agff_B&asuiv2.=0.009; 
%let tx_csp_agff_B&asuiv2.=0.013;

%let tx_css_agff_B&asuiv3.=0.009; 
%let tx_csp_agff_B&asuiv3.=0.013;

%let tx_css_agff_B&asuiv4.=0.009; 
%let tx_csp_agff_B&asuiv4.=0.013;

/*Assiette : entre 4 et 8 PSS*/
%let tx_css_agff_C&asuiv2.=0;
%let tx_csp_agff_C&asuiv2.=0;

%let tx_css_agff_C&asuiv3.=0.009; 
%let tx_csp_agff_C&asuiv3.=0.013;

%let tx_css_agff_C&asuiv4.=0.009; 
%let tx_csp_agff_C&asuiv4.=0.013;

/*APEC*/
/*Assiette : entre 1 et 4 PSS*/
%let tx_css_apec&asuiv2.=0.00024; 
%let tx_csp_apec&asuiv2.=0.00036; 

%let tx_css_apec&asuiv3.=0.00024; 
%let tx_csp_apec&asuiv3.=0.00036; 

%let tx_css_apec&asuiv4.=0.00024; 
%let tx_csp_apec&asuiv4.=0.00036; 


	/** All�gements g�n�raux **/

%let tx_allg_m20sal&asuiv2.=0.2795;
%let tx_allg_p20sal&asuiv2.=0.2835;
%let plaf_allg&asuiv2.=1.6;     

%let tx_allg_m20sal&asuiv3.=0.2802;
%let tx_allg_p20sal&asuiv3.=0.2842;
%let plaf_allg&asuiv3.=1.6;  
 

%let tx_allg_m20sal&asuiv4.=0.281;
%let tx_allg_p20sal&asuiv4.=0.285;
%let plaf_allg&asuiv4.=1.6;   


	/** Total non cadres **/

/*Entre 0 et 1 PSS*/
%let tx_css_nc1_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_vieil&asuiv2.+&&tx_css_assedic&asuiv2.+&&tx_css_ret1&asuiv2.+&&tx_css_agff_nc1&asuiv2.
+&&tx_css_vieil_tot&asuiv2.); 
%let tx_css_nc1_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_vieil&asuiv3.+&&tx_css_assedic&asuiv3.+&&tx_css_ret1&asuiv3.+&&tx_css_agff_nc1&asuiv3.
+&&tx_css_vieil_tot&asuiv3.); 
%let tx_css_nc1_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_vieil&asuiv4.+&&tx_css_assedic&asuiv4.+&&tx_css_ret1&asuiv4.+&&tx_css_agff_nc1&asuiv4.
+&&tx_css_vieil_tot&asuiv4.); 

%let tx_csp_nc1_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_vieil&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.
+&&tx_csp_assedic&asuiv2.+&&tx_csp_AGS&asuiv2.+&&tx_csp_ret1&asuiv2.+&&tx_csp_agff_nc1&asuiv2.+&&tx_csp_fnal&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); 
%let tx_csp_nc1_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_vieil&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.
+&&tx_csp_assedic&asuiv3.+&&tx_csp_AGS&asuiv3.+&&tx_csp_ret1&asuiv3.+&&tx_csp_agff_nc1&asuiv3.+&&tx_csp_fnal&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); 
%let tx_csp_nc1_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_vieil&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.
+&&tx_csp_assedic&asuiv4.+&&tx_csp_AGS&asuiv4.+&&tx_csp_ret1&asuiv4.+&&tx_csp_agff_nc1&asuiv4.+&&tx_csp_fnal&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); 

/*Entre 1 et 3 PSS*/
%let tx_css_nc2_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_assedic&asuiv2.+&&tx_css_ret2&asuiv2.+&&tx_css_agff_nc2&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_csp_nc2_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_assedic&asuiv2.
+&&tx_csp_AGS&asuiv2.+&&tx_csp_ret2&asuiv2.+&&tx_csp_agff_nc2&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); 

%let tx_css_nc2_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_assedic&asuiv3.+&&tx_css_ret2&asuiv3.+&&tx_css_agff_nc2&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_csp_nc2_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_assedic&asuiv3.
+&&tx_csp_AGS&asuiv3.+&&tx_csp_ret2&asuiv3.+&&tx_csp_agff_nc2&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); 

%let tx_css_nc2_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_assedic&asuiv4.+&&tx_css_ret2&asuiv4.+&&tx_css_agff_nc2&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_csp_nc2_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_assedic&asuiv4.
+&&tx_csp_AGS&asuiv4.+&&tx_csp_ret2&asuiv4.+&&tx_csp_agff_nc2&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); 

/*Entre 3 et 4 PSS*/
%let tx_css_nc3_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_assedic&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_csp_nc3_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_assedic&asuiv2.
+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.);

%let tx_css_nc3_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_assedic&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_csp_nc3_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_assedic&asuiv3.
+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.);

%let tx_css_nc3_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_assedic&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_csp_nc3_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_assedic&asuiv4.
+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.);

/*4 PSS ou plus*/
%let tx_css_nc4_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_csp_nc4_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); 

%let tx_css_nc4_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_csp_nc4_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); 

%let tx_css_nc4_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_csp_nc4_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); 



	/** Total cadres **/

/*Entre 0 et 1 PSS*/
%let tx_css_c1_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_vieil&asuiv2.+&&tx_css_assedic&asuiv2.+&&tx_css_retA&asuiv2.+&&tx_css_agff_A&asuiv2.
+&&tx_css_cet&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_csp_c1_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_vieil&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_assedic&asuiv2.
+&&tx_csp_AGS&asuiv2.+&&tx_csp_retA&asuiv2.+&&tx_csp_agff_A&asuiv2.+&&tx_csp_cet&asuiv2.+&&tx_csp_deces&asuiv2.+&&tx_csp_fnal&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); 

%let tx_css_c1_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_vieil&asuiv3.+&&tx_css_assedic&asuiv3.+&&tx_css_retA&asuiv3.+&&tx_css_agff_A&asuiv3.
+&&tx_css_cet&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_csp_c1_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_vieil&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_assedic&asuiv3.
+&&tx_csp_AGS&asuiv3.+&&tx_csp_retA&asuiv3.+&&tx_csp_agff_A&asuiv3.+&&tx_csp_cet&asuiv3.+&&tx_csp_deces&asuiv3.+&&tx_csp_fnal&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); 

%let tx_css_c1_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_vieil&asuiv4.+&&tx_css_assedic&asuiv4.+&&tx_css_retA&asuiv4.+&&tx_css_agff_A&asuiv4.
+&&tx_css_cet&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_csp_c1_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_vieil&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_assedic&asuiv4.
+&&tx_csp_AGS&asuiv4.+&&tx_csp_retA&asuiv4.+&&tx_csp_agff_A&asuiv4.+&&tx_csp_cet&asuiv4.+&&tx_csp_deces&asuiv4.+&&tx_csp_fnal&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); 

/*Entre 1 et 4 PSS*/
%let tx_css_c2_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_assedic&asuiv2.+&&tx_css_apec&asuiv2.+&&tx_css_retB&asuiv2.+&&tx_css_agff_B&asuiv2.
+&&tx_css_cet&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_csp_c2_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_assedic&asuiv2.
+&&tx_csp_AGS&asuiv2.+&&tx_csp_apec&asuiv2.+&&tx_csp_retB&asuiv2.+&&tx_csp_agff_B&asuiv2.+&&tx_csp_cet&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); 

%let tx_css_c2_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_assedic&asuiv3.+&&tx_css_apec&asuiv3.+&&tx_css_retB&asuiv3.+&&tx_css_agff_B&asuiv3.
+&&tx_css_cet&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_csp_c2_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_assedic&asuiv3.
+&&tx_csp_AGS&asuiv3.+&&tx_csp_apec&asuiv3.+&&tx_csp_retB&asuiv3.+&&tx_csp_agff_B&asuiv3.+&&tx_csp_cet&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); 

%let tx_css_c2_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_assedic&asuiv4.+&&tx_css_apec&asuiv4.+&&tx_css_retB&asuiv4.+&&tx_css_agff_B&asuiv4.
+&&tx_css_cet&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_csp_c2_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_assedic&asuiv4.
+&&tx_csp_AGS&asuiv4.+&&tx_csp_apec&asuiv4.+&&tx_csp_retB&asuiv4.+&&tx_csp_agff_B&asuiv4.+&&tx_csp_cet&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); 

/*Entre 4 et 8 PSS*/
%let tx_css_c3_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_retC&asuiv2.+&&tx_css_cet&asuiv2.+&&tx_css_vieil_tot&asuiv2. + &&tx_css_agff_C&asuiv2.); 
%let tx_csp_c3_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_retC&asuiv2.
+&&tx_csp_cet&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2. + &&tx_csp_agff_C&asuiv2. );

%let tx_css_c3_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_retC&asuiv3.+&&tx_css_cet&asuiv3.+&&tx_css_vieil_tot&asuiv3. + &&tx_css_agff_C&asuiv3.); 
%let tx_csp_c3_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_retC&asuiv3.
+&&tx_csp_cet&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3. + &&tx_csp_agff_C&asuiv3.);

%let tx_css_c3_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_retC&asuiv4.+&&tx_css_cet&asuiv4.+&&tx_css_vieil_tot&asuiv4. + &&tx_css_agff_C&asuiv4.); 
%let tx_csp_c3_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_retC&asuiv4.
+&&tx_csp_cet&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4. + &&tx_csp_agff_C&asuiv4.);

/*8 PSS ou plus*/
%let tx_css_c4_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_csp_c4_&asuiv2.=%sysevalf(&&tx_csp_mmdi&asuiv2.+&&tx_csp_solauto&asuiv2.+&&tx_csp_AF&asuiv2.+&&tx_csp_ATMP&asuiv2.+&&tx_csp_tap&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); 

%let tx_css_c4_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_csp_c4_&asuiv3.=%sysevalf(&&tx_csp_mmdi&asuiv3.+&&tx_csp_solauto&asuiv3.+&&tx_csp_AF&asuiv3.+&&tx_csp_ATMP&asuiv3.+&&tx_csp_tap&asuiv3.+&&tx_csp_vieil_tot&asuiv3.);

%let tx_css_c4_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_csp_c4_&asuiv4.=%sysevalf(&&tx_csp_mmdi&asuiv4.+&&tx_csp_solauto&asuiv4.+&&tx_csp_AF&asuiv4.+&&tx_csp_ATMP&asuiv4.+&&tx_csp_tap&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); 



/**************************************************************************************************************************************************************/
/*		c. CSG et CRDS sur les salaires								 		    															                  */
/**************************************************************************************************************************************************************/

	/** CSG sur les salaires **/

/*Assiette pour partie inf�rieure � 4P*/
%let ass_csg_sal&asuiv2.=0.9825; 
%let ass_csg_sal&asuiv3.=0.9825; 
%let ass_csg_sal&asuiv4.=0.9825; 

/*CSG d�ductible*/
%let tx_csgd_sal&asuiv.=0.051;
%let tx_csgd_sal&asuiv2.=0.051;
%let tx_csgd_sal&asuiv3.=0.051;
%let tx_csgd_sal&asuiv4.=0.051;

/*CSG non d�ductible*/
%let tx_csgi_sal&asuiv.=0.024;
%let tx_csgi_sal&asuiv2.=0.024;
%let tx_csgi_sal&asuiv3.=0.024;
%let tx_csgi_sal&asuiv4.=0.024;

	/** CRDS **/                                                                                                                                                        
%let tx_crds_sal&asuiv.=0.005;
%let tx_crds_sal&asuiv2.=0.005;    
%let tx_crds_sal&asuiv3.=0.005;  
%let tx_crds_sal&asuiv4.=0.005;  


/**************************************************************************************************************************************************************/
/*				6- Cotisations des agents publics														  								     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Cotisations des fonctionnaires							 		    															                  */
/**************************************************************************************************************************************************************/

/*Pension civile*/
/*D�cret n�2014-1531 du 17 d�cembre 2014 - art. 11*/
%let tx_css_pc&asuiv2.=0.0954;
%let tx_css_pc&asuiv3.=0.0994;
%let tx_css_pc&asuiv4.=0.1029;

/*Contribution employeur de l'�tat*/ 
%let tx_csp_pc_etat&asuiv2.=0.7428;
%let tx_csp_pc_etat&asuiv3.=0.7428;
%let tx_csp_pc_etat&asuiv4.=0.7428;

/*Contribution employeur au CNRACL : r�gime de retraite obligatoire de base, � points, des fonctionnaires titulaires de la fonction publique territoriale*/
/*D�cret n�2014-1531 du 17 d�cembre 2014 - art. 6*/
%let tx_csp_pc_apul&asuiv2.=0.305;
%let tx_csp_pc_apul&asuiv3.=0.306; 
%let tx_csp_pc_apul&asuiv4.=0.3065;

/*Cotisation militaires*/
%let tx_csp_pc_mili&asuiv2.=1.2607;		/*circulaire du 18 juillet 2014*/
%let tx_csp_pc_mili&asuiv3.=1.2607; 	/*circulaire du 15 d�cembre 2015*/
%let tx_csp_pc_mili&asuiv4.=1.2607;

/*Retraite additionnelle de la fonction publique*/
/*D�cret n� 2004-569 du 18 juin 2004 relatif � la retraite additionnelle de la fonction publique*/
%let tx_css_rafp&asuiv2.=0.05;
%let tx_css_rafp&asuiv3.=0.05;
%let tx_css_rafp&asuiv4.=0.05;

%let tx_css_rafp_max&asuiv2.=0.2; 		/*dans la limite de 20% du traitement brut*/
%let tx_css_rafp_max&asuiv3.=0.2; 		/*dans la limite de 20% du traitement brut*/
%let tx_css_rafp_max&asuiv4.=0.2; 		/*dans la limite de 20% du traitement brut*/

/*Solidarit�*/
%let tx_css_sol&asuiv2.=0.01;
%let tx_css_sol&asuiv3.=0.01;
%let tx_css_sol&asuiv4.=0.01;


/*FNAL*/ 
/*Somme des cotisations plafonn�es et d�plafonn�es car on est toujours au-del� de 20 salari�s pour la fonction publique*/
%let tx_csp_fnal_etat&asuiv2.=0.005;
%let tx_csp_fnal_etat&asuiv3.=0.005;
%let tx_csp_fnal_etat&asuiv4.=0.005;

/*Maladie*/
%let tx_csp_maladie_f&asuiv2.=0.097;
%let tx_csp_maladie_f&asuiv3.=0.097;
%let tx_csp_maladie_f&asuiv4.=0.097;

/*Charge �tat maladie*/
%let tx_csp_CEmaladie_f&asuiv2.=0.029;
%let tx_csp_CEmaladie_f&asuiv3.=0.029;
%let tx_csp_CEmaladie_f&asuiv4.=0.029;

/*Charge �tat accident du travail*/
%let tx_csp_CEAT&asuiv2.=0.0009;
%let tx_csp_CEAT&asuiv3.=0.0009;
%let tx_csp_CEAT&asuiv4.=0.0009;

/* Part des primes dans la r�mun�ration des agents*/
%let tx_prim&asuiv2.=0.20;		/*voir insee premiere N 1662*/
%let tx_prim&asuiv3.=0.20;
%let tx_prim&asuiv4.=0.20;


/**************************************************************************************************************************************************************/
/*		b. Cotisations sociales des non titulaires					 		    															                  */
/**************************************************************************************************************************************************************/

/*Retraite compl�mentaire : ircantec*/
/*Assiette entre 0 et 1 PSS*/
%let tx_css_ircantec1&asuiv2.=0.0264;
%let tx_csp_ircantec1&asuiv2.=0.0396;

%let tx_css_ircantec1&asuiv3.=0.0272;
%let tx_csp_ircantec1&asuiv3.=0.0408;

%let tx_css_ircantec1&asuiv4.=0.0280;
%let tx_csp_ircantec1&asuiv4.=0.0420;

/*Assiette entre 1 et 8 PSS*/
%let tx_css_ircantec2&asuiv2.=0.0658;
%let tx_csp_ircantec2&asuiv2.=0.1218;

%let tx_css_ircantec2&asuiv3.=0.0675;
%let tx_csp_ircantec2&asuiv3.=0.1235;

%let tx_css_ircantec2&asuiv4.=0.0695;
%let tx_csp_ircantec2&asuiv4.=0.1255;


	/** Total non titulaires **/

/*Entre 0 et 1 PSS*/
%let tx_css_nt1_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_vieil&asuiv2.+&&tx_css_ircantec1&asuiv2.+&&tx_css_vieil_tot&asuiv2.);
%let tx_css_rc_nt1_&asuiv2.=%sysevalf(&&tx_css_vieil&asuiv2.+&&tx_css_ircantec1&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); /*Retraites ch�mage*/

%let tx_css_nt1_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_vieil&asuiv3.+&&tx_css_ircantec1&asuiv3.+&&tx_css_vieil_tot&asuiv3.);
%let tx_css_rc_nt1_&asuiv3.=%sysevalf(&&tx_css_vieil&asuiv3.+&&tx_css_ircantec1&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); /*Retraites ch�mage*/

%let tx_css_nt1_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_vieil&asuiv4.+&&tx_css_ircantec1&asuiv4.+&&tx_css_vieil_tot&asuiv4.);
%let tx_css_rc_nt1_&asuiv4.=%sysevalf(&&tx_css_vieil&asuiv4.+&&tx_css_ircantec1&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); /*Retraites ch�mage*/

/*1 PSS ou plus*/
%let tx_css_nt2_&asuiv2.=%sysevalf(&&tx_css_mmdi&asuiv2.+&&tx_css_ircantec2&asuiv2.+&&tx_css_vieil_tot&asuiv2.); 
%let tx_css_rc_nt2_&asuiv2.=%sysevalf(&&tx_css_ircantec2&asuiv2.+&&tx_csp_vieil_tot&asuiv2.); /*Retraites ch�mage*/

%let tx_css_nt2_&asuiv3.=%sysevalf(&&tx_css_mmdi&asuiv3.+&&tx_css_ircantec2&asuiv3.+&&tx_css_vieil_tot&asuiv3.); 
%let tx_css_rc_nt2_&asuiv3.=%sysevalf(&&tx_css_ircantec2&asuiv3.+&&tx_csp_vieil_tot&asuiv3.); /*Retraites ch�mage*/

%let tx_css_nt2_&asuiv4.=%sysevalf(&&tx_css_mmdi&asuiv4.+&&tx_css_ircantec2&asuiv4.+&&tx_css_vieil_tot&asuiv4.); 
%let tx_css_rc_nt2_&asuiv4.=%sysevalf(&&tx_css_ircantec2&asuiv4.+&&tx_csp_vieil_tot&asuiv4.); /*Retraites ch�mage*/



/**************************************************************************************************************************************************************/
/*				7- Cotisations des non salari�s agricoles (chefs d'exploitation)												  								     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Assiettes minimales					 		    																				                  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Exprim�es en nombre de smic horaire :				 		    																		                  */
/*		- amexa : assurance maladie des exploitants agricoles																								  */
/*		- avi : assurance vieillesse individuelle 																											  */
/*		- ava : assurance vieillesse agricole 																												  */
/*		- retraite compl�mentaire obligatoire 																												  */
/**************************************************************************************************************************************************************/

%let ass_min_amexa&asuiv.=%sysevalf(800*&&smic_hor_brut&asuiv.) ;
%let ass_min_inval&asuiv.=0 ;
%let ass_min_avi&asuiv.=%sysevalf(800*&&smic_hor_brut&asuiv2.);
%let ass_min_ava&asuiv.=%sysevalf(600*&&smic_hor_brut&asuiv2.);
%let ass_min_rco&asuiv.=%sysevalf(1820*&&smic_hor_brut&asuiv2.);

%let ass_min_amexa&asuiv2.=%sysevalf(12*0.11*&&PSS&asuiv2.) ; /*D. 731-89 du code rural et de la p�che maritime - version pr� 2016 : D�cret n� 2015-1365 du 28 octobre 2015*/
%let ass_min_inval&asuiv2.=0 ;
%let ass_min_avi&asuiv2.=%sysevalf(800*&&smic_hor_brut&asuiv2.);
%let ass_min_ava&asuiv2.=%sysevalf(600*&&smic_hor_brut&asuiv2.);
%let ass_min_rco&asuiv2.=%sysevalf(1820*&&smic_hor_brut&asuiv2.);

%let ass_min_amexa&asuiv3.=0 ; /*suppression de l'assiette minimale : d�cret n� 2015-1856 du 30 d�cembre 2015 */
%let ass_min_inval&asuiv3.=%sysevalf(12*0.115*&&PSS&asuiv3.); /*D. 731-89 du code rural et de la p�che maritime : assiette min de 11,5% du PASS */
%let ass_min_avi&asuiv3.=%sysevalf(800*&&smic_hor_brut&asuiv3.);
%let ass_min_ava&asuiv3.=%sysevalf(600*&&smic_hor_brut&asuiv3.);
%let ass_min_rco&asuiv3.=%sysevalf(1820*&&smic_hor_brut&asuiv3.);

%let ass_min_amexa&asuiv4.=0 ; /*suppression de l'assiette minimale : d�cret n� 2015-1856 du 30 d�cembre 2015 */
%let ass_min_inval&asuiv4.=%sysevalf(12*0.115*&&PSS&asuiv4.); /*D. 731-89 du code rural et de la p�che maritime : assiette min de 11,5% du PASS */
%let ass_min_avi&asuiv4.=%sysevalf(800*&&smic_hor_brut&asuiv4.);
%let ass_min_ava&asuiv4.=%sysevalf(600*&&smic_hor_brut&asuiv4.);
%let ass_min_rco&asuiv4.=%sysevalf(1820*&&smic_hor_brut&asuiv4.);


/**************************************************************************************************************************************************************/
/*		b. Taux de cotisations					 		    																				                  */
/**************************************************************************************************************************************************************/

/*Assurance maladie des exploitants agricoles*/
%let tx_css_amexa_princ&asuiv.=0.1084;
%let tx_css_amexa_princ&asuiv2.=0.1084;
%let tx_css_amexa_princ&asuiv3.=0.0304; /*article D. 731-91 du code rural et de la p�che maritime : d�cret n� 2016-392 du 31 mars 2016*/
%let tx_css_amexa_princ&asuiv4.=0.0304;

%let tx_css_amexa_sec&asuiv.=0.0828;
%let tx_css_amexa_sec&asuiv2.=0.0828;
%let tx_css_amexa_sec&asuiv3.=0.0748; 	/*article D. 731-92 du code rural et de la p�che maritime*/
%let tx_css_amexa_sec&asuiv4.=0.0748; 	/*article D. 731-92 du code rural et de la p�che maritime*/
            
%let mt_css_amexa_sec_&asuiv.=0;
%let mt_css_amexa_sec_&asuiv2.=0;
%let mt_css_amexa_sec_&asuiv3.=0;
%let mt_css_amexa_sec_&asuiv4.=0;

/*Assurance invalidit� des exploitants agricoles*/
%let tx_css_inval&asuiv.=0;
%let tx_css_inval&asuiv2.=0;
%let tx_css_inval&asuiv3.=0.008; 		/*article D. 731-89 du code rural et de la p�che maritime : d�cret n� 2015-1856 du 30 d�cembre 2015*/ 
%let tx_css_inval&asuiv4.=0.008;

/*Allocation familliales*/
%let tx_css_pfa&asuiv.=0.0525;
%let tx_css_pfa&asuiv2.=0.0525;
%let tx_css_pfa&asuiv3.=0.0525;
%let tx_css_pfa&asuiv4.=0.0525;

/*Exon�ration cotisation familiale : valable pour l'ensemble des ind�pendants*/
%let tx_exo_pfa_bas_revenus&asuiv.=0; 
%let tx_exo_pfa_bas_revenus&asuiv2.=0.031; 
%let tx_exo_pfa_bas_revenus&asuiv3.=0.031; 
%let tx_exo_pfa_bas_revenus&asuiv4.=0.031; 

%let seuil_tx_af_red&asuiv.=%sysevalf(12*1.1*&&PSS&asuiv.);		/*110% du PSS annuel*/
%let seuil_tx_af_red&asuiv2.=%sysevalf(12*1.1*&&PSS&asuiv2.);	
%let seuil_tx_af_red&asuiv3.=%sysevalf(12*1.1*&&PSS&asuiv3.);
%let seuil_tx_af_red&asuiv4.=%sysevalf(12*1.1*&&PSS&asuiv4.);

%let sortie_tx_af_red&asuiv.=%sysevalf(12*1.4*&&PSS&asuiv.);	/*140% du PSS annuel*/
%let sortie_tx_af_red&asuiv2.=%sysevalf(12*1.4*&&PSS&asuiv2.);	
%let sortie_tx_af_red&asuiv3.=%sysevalf(12*1.4*&&PSS&asuiv3.);	
%let sortie_tx_af_red&asuiv4.=%sysevalf(12*1.4*&&PSS&asuiv4.);	


/*Assurance vieillesse individuelle - AVI*/ 
/*Article D731-121 Code rural et de la p�che maritime*/
%let tx_css_avi&asuiv.=0.0328;
%let tx_css_avi&asuiv2.=0.0330;
%let tx_css_avi&asuiv3.=0.0332;
%let tx_css_avi&asuiv4.=0.0332;

/*Assurance vieillesse agricole - AVA*/ 
/*Article D731-122 Code rural et de la p�che maritime*/
%let tx_css_ava_plaf&asuiv.=0.1139;
%let tx_css_ava_plaf&asuiv2.=0.1147;
%let tx_css_ava_plaf&asuiv3.=0.1155;
%let tx_css_ava_plaf&asuiv4.=0.1155;

/*Assurance vieillesse agricole d�plafonn�e - AVAD*/ 
/*Article D731-124 Code rural et de la p�che maritime */
%let tx_css_ava_deplaf&asuiv.=0.0194;
%let tx_css_ava_deplaf&asuiv2.=0.0204;
%let tx_css_ava_deplaf&asuiv3.=0.0214;
%let tx_css_ava_deplaf&asuiv4.=0.0224;

/*Retraite compl�mentaire*/
%let tx_css_rco_&asuiv.=0.03;
%let tx_css_rco_&asuiv2.=0.03;
%let tx_css_rco_&asuiv3.=0.03;
%let tx_css_rco_&asuiv4.=0.03;

/*Accident du travail*/
/*Cotisation forfaitaire suivant risque : on prend ici une moyenne des cat�gories A B C D E*/
%let mt_css_atexa_cp_&asuiv.=430.876;		/*Arr�t� du 17 d�cembre 2013*/
%let mt_css_atexa_cs_&asuiv.=215.44 ;
%let mt_css_atexa_af_&asuiv.=%sysevalf(0.3848*&&mt_css_atexa_cp_&asuiv.) ;
%let mt_css_atexa_cp_&asuiv2.=430.924;		/*Arr�t� du 15 d�cembre 2014*/
%let mt_css_atexa_cs_&asuiv2.=215.462 ; 
%let mt_css_atexa_af_&asuiv2.=%sysevalf(0.3848*&&mt_css_atexa_cp_&asuiv2.) ;  
%let mt_css_atexa_cp_&asuiv3.=435.586 ; 	/*Arr�t� du 15 d�cembre 2015*/
%let mt_css_atexa_cs_&asuiv3.=217.794 ; 
%let mt_css_atexa_af_&asuiv3.=%sysevalf(0.3848*&&mt_css_atexa_cp_&asuiv3.) ;
%let mt_css_atexa_cp_&asuiv4.=454.39 ; 		/*Arr�t� du 18 d�cembre 2016*/
%let mt_css_atexa_cs_&asuiv4.=217.296 ; 
%let mt_css_atexa_af_&asuiv4.=%sysevalf(0.3848*&&mt_css_atexa_cp_&asuiv4.) ;

/*Formation professionnelle*/
%let tx_css_vivea_&asuiv.=0.0061;
%let binf_vivea_&asuiv.=%sysevalf(12*0.0017*&&PSS&asuiv.);		/*0.17% du PSS*/
%let bsup_vivea_&asuiv.=%sysevalf(12*0.0089*&&PSS&asuiv.);		/*0.89% du PSS*/
 
%let tx_css_vivea_&asuiv2.=0.0061;
%let binf_vivea_&asuiv2.=%sysevalf(12*0.0017*&&PSS&asuiv2.);	
%let bsup_vivea_&asuiv2.=%sysevalf(12*0.0089*&&PSS&asuiv2.);	

%let tx_css_vivea_&asuiv3.=0.0061;
%let binf_vivea_&asuiv3.=%sysevalf(12*0.0017*&&PSS&asuiv3.);	
%let bsup_vivea_&asuiv3.=%sysevalf(12*0.0089*&&PSS&asuiv3.);	

%let tx_css_vivea_&asuiv4.=0.0061;
%let binf_vivea_&asuiv4.=%sysevalf(12*0.0017*&&PSS&asuiv4.);	
%let bsup_vivea_&asuiv4.=%sysevalf(12*0.0089*&&PSS&asuiv4.);	


/**************************************************************************************************************************************************************/
/*		c. Sp�cificit� des aidants familiaux	 		    																				                  */
/**************************************************************************************************************************************************************/

/* Amexa*/
%let tx_css_amexa_AF&asuiv.=0.66;
%let tx_css_amexa_AF&asuiv2.=0.66;
%let tx_css_amexa_AF&asuiv3.=0.66;
%let tx_css_amexa_AF&asuiv4.=0.66;
%let plaf_amexa_AF&asuiv.=1880;
%let plaf_amexa_AF&asuiv2.=1896;
%let plaf_amexa_AF&asuiv3.=%sysevalf(&&plaf_amexa_AF&asuiv2.*&&smic_hor_brut&asuiv3./&&smic_hor_brut&asuiv2.);   /*Article D731-93 Code rural et de la p�che maritime*/
%let plaf_amexa_AF&asuiv4.=%sysevalf(&&plaf_amexa_AF&asuiv3.*&&smic_hor_brut&asuiv4./&&smic_hor_brut&asuiv3.);   /*Article D731-93 Code rural et de la p�che maritime*/       
%let ass_min_ava_AF&asuiv.=600; 
%let ass_min_ava_AF&asuiv2.=600; 
%let ass_min_ava_AF&asuiv3.=600; 
%let ass_min_ava_AF&asuiv4.=600; 


/**************************************************************************************************************************************************************/
/*				8- Cotisations des non salari�s artisans et commer�ants																	     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Assiettes minimales					 		    																				                  */
/**************************************************************************************************************************************************************/

/*Maternit� maladie*/ 
/*D.612-5 du Code de la S�curit� Sociale : attention, abrog� au 1er janvier 2016*/
%let ass_min_canam&asuiv.=%sysevalf(12*0.40*&&PSS&asuiv.);  
%let ass_min_canam&asuiv2.=%sysevalf(12*0.10*&&PSS&asuiv2.);  /* 10 % du PSS*/
%let ass_min_canam&asuiv3.=0;  								  /*Abrogation au 1er janvier 2016*/
%let ass_min_canam&asuiv4.=0;

/*Retraite de base*/ 
/*D.633-2 du Code de la S�curit� Sociale*/
/*Pour la retraite : l'assiette minimale est semblable � celle des professions lib�rales : article  D642-4*/
%let ass_min_rsi&asuiv.=%sysevalf(12*0.0525*&&PSS&asuiv.); 	/*5,25% du PSS*/
%let ass_min_rsi&asuiv2.=%sysevalf(12*0.077*&&PSS&asuiv2.); /*7,7% du PSS*/
%let ass_min_rsi&asuiv3.=%sysevalf(12*0.115*&&PSS&asuiv3.); /*11,5% du PSS*/
%let ass_min_rsi&asuiv4.=%sysevalf(12*0.115*&&PSS&asuiv4.); 


/*Retraite compl�mentaire*/
/*D.635-2 du Code de la S�curit� Sociale*/
%let ass_min_rcoi&asuiv.=%sysevalf(12*0.0525*&&PSS&asuiv.); 
%let ass_min_rcoi&asuiv2.=%sysevalf(12*0.077*&&PSS&asuiv2.);
%let ass_min_rcoi&asuiv3.=0; 								/*D�cret n� 2015-1856 du 30 d�cembre 2015*/
%let ass_min_rcoi&asuiv4.=0;

/*Invalidit� d�c�s*/ 
/*D635-12 du Code de la S�curit� Sociale*/    
%let ass_min_inv&asuiv.=%sysevalf(12*0.20*&&PSS&asuiv.);	/*20% du PSS*/
%let ass_min_inv&asuiv2.=%sysevalf(12*0.20*&&PSS&asuiv2.);	
%let ass_min_inv&asuiv3.=%sysevalf(12*0.115*&&PSS&asuiv3.);	/*11,5% du PSS*/
%let ass_min_inv&asuiv4.=%sysevalf(12*0.115*&&PSS&asuiv4.);	

/*Indemnit�s journali�res*/ 
/*D612-9 du Code de la S�curit� Sociale*/
%let ass_min_ij&asuiv.=%sysevalf(12*0.4*&&PSS&asuiv.);
%let ass_min_ij&asuiv2.=%sysevalf(12*0.4*&&PSS&asuiv2.); 	/*40 % du PASS*/
%let ass_min_ij&asuiv3.=%sysevalf(12*0.4*&&PSS&asuiv3.); 	/*40 % du PASS*/
%let ass_min_ij&asuiv4.=%sysevalf(12*0.4*&&PSS&asuiv4.); 	/*40 % du PASS*/


/*************************************************************************************************************************************************************/
/*		b. Plafonds								 		    																				                 */
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/* Depuis le 1er janvier 2013, le RCI (R�gime compl�mentaire des ind�pendants) couvre l'ensemble des ind�pendants.							                 */
/* Les plafonds sont exprim�s en plafond de la s�curit� sociale (PSS)																						 */
/*************************************************************************************************************************************************************/

%let plaf_cnavpl1&asuiv.=%sysevalf(12*&&PSS&asuiv.*0.85);
%let plaf_cnavpl2&asuiv.=%sysevalf(12*&&PSS&asuiv.*5);
%let plaf_rco1_ic&asuiv.=37513;
%let plaf_rco2_ic&asuiv.=%sysevalf(12*&&PSS&asuiv.*4);
%let plaf_ij&asuiv.     =%sysevalf(12*&&PSS&asuiv.*5);


%let plaf_cnavpl1&asuiv2.=%sysevalf(12*&&PSS&asuiv2.*1); 
%let plaf_cnavpl2&asuiv2.=%sysevalf(12*&&PSS&asuiv2.*5); 
%let plaf_rco1_ic&asuiv2.=37513; 
%let plaf_rco2_ic&asuiv2.=%sysevalf(12*&&PSS&asuiv2.*4); 
%let plaf_ij&asuiv2.     =%sysevalf(12*&&PSS&asuiv2.*5); ; 

%let plaf_cnavpl1&asuiv3.=%sysevalf(12*&&PSS&asuiv3.*1); 
%let plaf_cnavpl2&asuiv3.=%sysevalf(12*&&PSS&asuiv3.*5); 
%let plaf_rco1_ic&asuiv3.=37546;
%let plaf_rco2_ic&asuiv3.=%sysevalf(12*&&PSS&asuiv3.*4); 
%let plaf_ij&asuiv3.       =%sysevalf(12*&&PSS&asuiv3.*5) ; 

%let plaf_cnavpl1&asuiv4.=%sysevalf(12*&&PSS&asuiv4.*1);
%let plaf_cnavpl2&asuiv4.=%sysevalf(12*&&PSS&asuiv4.*5); 
%let plaf_rco1_ic&asuiv4.=37546;
%let plaf_rco2_ic&asuiv4.=%sysevalf(12*&&PSS&asuiv4.*4); 
%let plaf_ij&asuiv4.     =%sysevalf(12*&&PSS&asuiv4.*5); 

/*************************************************************************************************************************************************************/
/*		c. Taux de cotisations					 		    																				                 */
/*************************************************************************************************************************************************************/

/*Assurance maladie*/ 
/*D.612-4 du Code de la S�curit� Sociale*/
%let tx_css_canam1&asuiv.=0.065;
%let tx_css_canam2&asuiv.=0;
%let seuil_css_canam&asuiv.=0.7;
%let tx_css_ij&asuiv.=0.007;

%let tx_css_canam1&asuiv2.=0.065;
%let tx_css_canam2&asuiv2.=0;
%let seuil_css_canam&asuiv2.=0.7;
%let tx_css_ij&asuiv2.=0.007;

%let tx_css_canam1&asuiv3.=0.065;
%let tx_css_canam2&asuiv3.=0.035;
%let seuil_css_canam&asuiv3.=0.7;
%let tx_css_ij&asuiv3.=0.007;

%let tx_css_canam1&asuiv4.=0.065;
%let tx_css_canam2&asuiv4.=0.035;
%let seuil_css_canam&asuiv4.=0.7;
%let tx_css_ij&asuiv4.=0.007;


/*Allocations familiales*/ 
/* Les macros permettant de d�finir un all�gement de cotisations sociales sont d�finies plus haut (voir exploitants agricoles)*/
%let tx_css_af_i&asuiv.=0.0525;
%let tx_css_af_i&asuiv2.=0.0525;
%let tx_css_af_i&asuiv3.=0.0525;
%let tx_css_af_i&asuiv4.=0.0525;


/*Formation professionnelle*/ 
   
        /*Pour les commer�ants : L6331-48 du Code du travail */
%let tx_css_fp_i&asuiv.=0.0025;
%let tx_css_fp_i&asuiv2.=0.0025;
%let tx_css_fp_i&asuiv3.=0.0025;
%let tx_css_fp_i&asuiv4.=0.0025;
        /*Pour les artisans : 1601 et 1601B du CGI (0.17 + 0.12)*/
%let tx_css_fp_art&asuiv.=0.0029;
%let tx_css_fp_art&asuiv2.=0.0029;
%let tx_css_fp_art&asuiv3.=0.0029;
%let tx_css_fp_art&asuiv4.=0.0029;

/*Assurance vieillesse de base en-dessous du PSS*/ 
/*Article D633-3 du Code de la S�curit� Sociale*/
%let tx_css_rsi1_&asuiv.=0.1695;
%let tx_css_rsi1_&asuiv2.=0.1705; 
%let tx_css_rsi1_&asuiv3.=0.1715; 
%let tx_css_rsi1_&asuiv4.=0.1715;

/*Assurance vieillesse d�plafonn�e, introduite en 2014*/ 
/*Article D633-3 du Code de la S�curit� Sociale*/  
%let tx_css_rsi_deplaf&asuiv.=0.0020;
%let tx_css_rsi_deplaf&asuiv2.=0.0035;  
%let tx_css_rsi_deplaf&asuiv3.=0.005; 
%let tx_css_rsi_deplaf&asuiv4.=0.006;

/*Pour les professions lib�rales */ 
/*D642-3 du Code de la S�curit� Sociale, d�cret 2014-1413 du 7/11/2014*/
/*Circulaire RSI 2013-004 du 17/01/2013*/
%let tx_css_rsi2_&asuiv.=0.1010;
%let tx_css_rsi3_&asuiv.=0.0187;

%let tx_css_rsi2_&asuiv2.=0.0823; 	/*En-dessous de 1 PSS : 8.23 + 1.87. Entre 1 et 5 PSS : 1.87*/
%let tx_css_rsi3_&asuiv2.=0.0187; 

%let tx_css_rsi2_&asuiv3.=0.0823; 
%let tx_css_rsi3_&asuiv3.=0.0187; 

%let tx_css_rsi2_&asuiv4.=0.0823; 
%let tx_css_rsi3_&asuiv4.=0.0187; 

%let tx_css_rco1_ic&asuiv.=0.07;	
%let tx_css_rco2_ic&asuiv.=0.08;

%let tx_css_rco1_ic&asuiv2.=0.07;   
%let tx_css_rco2_ic&asuiv2.=0.08; 

%let tx_css_rco1_ic&asuiv3.=0.07;   
%let tx_css_rco2_ic&asuiv3.=0.08; 

%let tx_css_rco1_ic&asuiv4.=0.07;   
%let tx_css_rco2_ic&asuiv4.=0.08; 


/*Invalidit� d�c�s*/  
/*D635-15 et D635-17 du Code de la S�curit� Sociale*/ 
%let tx_css_inv_art&asuiv.=0.016;
%let tx_css_inv_com&asuiv.=0.011;

%let tx_css_inv_art&asuiv2.=0.016; 
%let tx_css_inv_com&asuiv2.=0.011; 

%let tx_css_inv_art&asuiv3.=0.013; 
%let tx_css_inv_com&asuiv3.=0.013; 

%let tx_css_inv_art&asuiv4.=0.013; 
%let tx_css_inv_com&asuiv4.=0.013; 


/*************************************************************************************************************************************************************/
/*		d. Sp�cificit� des professions lib�rales				 		    																                 */
/*************************************************************************************************************************************************************/

/*Optionnel et d�pendant de la profession : on applique un taux moyen*/      
%let tx_css_rco_lib&asuiv.=0.1; 
%let tx_css_inv_lib&asuiv.=0.01;

%let tx_css_rco_lib&asuiv2.=0.1;
%let tx_css_inv_lib&asuiv2.=0.01;

%let tx_css_rco_lib&asuiv3.=0.1;
%let tx_css_inv_lib&asuiv3.=0.01;

%let tx_css_rco_lib&asuiv4.=0.1; 
%let tx_css_inv_lib&asuiv4.=0.01;



/*************************************************************************************************************************************************************/
/*				9- CSG, CRDS et cotisations sociales sur les revenus du patrimoine												     				 */
/*************************************************************************************************************************************************************/

/*Taux de CSG*/
%let tx_CSG_cap&asuiv2.=0.082;
%let tx_CSG_cap&asuiv3.=0.082;
%let tx_CSG_cap&asuiv4.=0.082;

/*Taux de pr�l�vements sociaux et contributions additionnelles*/
%let tx_PS_cap&asuiv2.=0.068;
%let tx_PS_cap&asuiv3.=0.068;
%let tx_PS_cap&asuiv4.=0.068;

/*Pr�l�vements sociaux � la source : revenus de placement*/
%let tx_PS_source&asuiv2.=0.068;
%let tx_PS_source&asuiv3.=0.068;
%let tx_PS_source&asuiv4.=0.068;

/*Compensation de l'int�gration de l'abattement de 20% au bar�me de l'IR sur les montants d�clar�s ligne GO */
%let comp_ab20&asuiv2. = 1.25; 
%let comp_ab20&asuiv3. = 1.25; 
%let comp_ab20&asuiv4. = 1.25;

/*Plafond d'exigibilit�*/
%let plaf_imposable&asuiv2.=61; 
%let plaf_imposable&asuiv3.=61; 
%let plaf_imposable&asuiv4.=61;

%let annee=20&acour.;       		/*ann�e correspondant aux revenus impos�s dans ERFS*/
%let an14=%sysevalf(20&acour.-14);  /*ann�e de naissance des personnes de 14 ans dans ERFS*/



/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*                       											II. Allocations logement                 										  	 	 */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/


%let revalo_AL=%sysevalf((&&revalo_irl&asuiv3.)*(9+3*(&&revalo_irl&asuiv4.))/12);


/*************************************************************************************************************************************************************/
/*				1- Loyer plafond (Lplf)																									     				 */
/*************************************************************************************************************************************************************/

/*Isol�, zone 1,2,3*/
%let Lplfiso1=%sysevalf(292.85*&revalo_AL.); %let Lplfiso2=%sysevalf(255.23*&revalo_AL.); %let Lplfiso3=%sysevalf(239.21*&revalo_AL.);

/*M�nage sans personne � charge , zone 1,2,3*/
%let Lplfc01=%sysevalf(353.20*&revalo_AL.);  %let Lplfc02=%sysevalf(312.40*&revalo_AL.);  %let Lplfc03=%sysevalf(289.99*&revalo_AL.);

/*Isol� ou m�nage, une personne � charge, zone 1,2,3*/
%let Lplf1e1=%sysevalf(399.19*&revalo_AL.);  %let Lplf1e2=%sysevalf(351.53*&revalo_AL.);  %let Lplf1e3=%sysevalf(325.15*&revalo_AL.);

/*Isol� ou m�nage, par personne � charge suppl�mentaire, zone 1,2,3*/
%let Lplfsup1=%sysevalf(57.91*&revalo_AL.);  %let Lplfsup2=%sysevalf(51.16*&revalo_AL.);  %let Lplfsup3=%sysevalf(46.60*&revalo_AL.);


/*************************************************************************************************************************************************************/
/*				2- Charges (C)																											     				 */
/*************************************************************************************************************************************************************/

/*0 personne � charge*/
%let C0pc=%sysevalf(53.27*&revalo_AL.); 

/*Par personne � charge suppl�mentaire*/
%let Csup=%sysevalf(12.07*&revalo_AL.);


/*************************************************************************************************************************************************************/
/*				3- Taux marginal pour le calcul de TL (TM1, TM2, TM3)																	     				 */
/*************************************************************************************************************************************************************/

/*Attention, les unit�s sont d�j� divis�es par 100*/
%let b_tm1=45; 
%let b_tm2=75;
%let tm1=0; 
%let tm2=0.0045; 
%let tm3=0.0068;


/*************************************************************************************************************************************************************/
/*				4- Ressources																											     				 */
/*************************************************************************************************************************************************************/

/*Le R0 n'est plus index� sur le RSA ou la BMAF mais sur l'IPC hors tabac en moyenne annuelle en n-2 (cf D�cret n� 2014-1739 du 29 d�cembre 2014)*/

/*R0*/ 
%let R0_iso = %sysfunc(floor(4562*&tx_revalo_plaf.)) ;
%let R0_co  = %sysfunc(floor(6534*&tx_revalo_plaf.)) ; 
%let R0_1pc = %sysfunc(floor(7793*&tx_revalo_plaf.)) ; 
%let R0_2pc = %sysfunc(floor(7969*&tx_revalo_plaf.)) ; 
%let R0_sup = %sysfunc(floor( 305*&tx_revalo_plaf.)) ; 

/*P0 : Participation minimale*/
%let P0min=%sysfunc(round(34.76*&revalo_AL.));

/*TF : Taux de participation selon la taille de la famille*/
%let TF_iso=0.0283; 
%let TF_c0=0.0315; 
%let TF_1pc=0.0270; 
%let TF_2pc=0.0238; 
%let TF_3pc=0.0201; 
%let TF_4pc=0.0185; 
%let TF_sup=0.006; 

/*Seuil de non versement*/
%let seuilal=15;

/*ressources minimales pour les �tudiants*/
/*attention, c'est le plancher pour les boursiers ne vivant pas en Crous*/
%let planch_et=%sysfunc(round(6100*&revalo_AL.));



/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*                       											III. Prestations familiales                 											 */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

/*Les montants des prestations sont exprim�s en % de la BMAF*/
/*Revalorisation de toutes les prestations au 1er avril, sauf pour les pensions et les allocations logement (octobre)*/

/*Bornes pour l'abattement forfaitaire de 10% sur les salaires dans la l�gislation IR (legislation 2016 sur revenus 2015)*/
/*Utilis�es dans le calcul de la base ressource des prestations familiales*/
%let abat_tsal_min=426; 
%let abat_tsal_min_cho=937; 
%let abat_tsal_max=12169;
%let abat_pens_min=379; 
%let abat_pens_max=3711;


/*************************************************************************************************************************************************************/
/*				1- Montant de la BMAF en moyenne annuelle																				     				 */
/*************************************************************************************************************************************************************/

%let bmaf13=403.79 ;
%let bmaf&asuiv2.=406.21 ;
%let bmaf&asuiv3.=406.52 ; 
%let bmaf&asuiv4.=%sysevalf(406.62*(3+9*&tx_revalo.)/12)  ;


/*************************************************************************************************************************************************************/
/*				2- Seuil de biactivit�																									     				 */
/*************************************************************************************************************************************************************/

/*Circulaire interminist�rielle N� DSS/2B/2011/447 du 1er d�cembre 2011 : le seuil est d�fini � 13,6% du PSS de l'ann�e N-2*/
%let seuil_biact=%sysfunc(round(0.136*&&PSS&asuiv4.));


/*************************************************************************************************************************************************************/
/*				3- Les allocations familiales																							     				 */
/*************************************************************************************************************************************************************/

%let tauxAF2=0.32; 
%let tauxAF_sup=0.41;

/*Le montant des allocations familiales est divis� par deux au-dessus de la borne 1 puis par 4 au-dessus de la borne 2*/
%let borne1_AF =    %sysfunc(round(56174*&tx_revalo_plaf.)); 
%let borne2_AF =    %sysfunc(round(78613*&tx_revalo_plaf.)); 
%let borne_AF_majo= %sysfunc(round( 5617*&tx_revalo_plaf.));

/*Allocation forfaitaire*/
%let tauxAFORF=0.20234;

/*Majorations pour �ge des personnes � charge*/
%let tx_maj_1419=0.16; 


/*************************************************************************************************************************************************************/
/*				4- PAJE																													     				 */
/*************************************************************************************************************************************************************/

%let annee_ref_paje=2010 ; /*pour simuler la r�forme de 2014 par rapport � l'ERFS 2013*/

/*************************************************************************************************************************************************************/
/*		a. Paje - allocation de base							 		    																                 */
/*************************************************************************************************************************************************************/

	/** Plafond de ressources **/

/*Les plafonds OLD servent pour les enfants n�s avant avril 2014*/
%let plaf_paje_m1_old =%sysfunc(round(35871*&tx_revalo_plaf.));   	/*plafond couple monoactif, 1 enfant*/
%let plaf_paje_m2_old =%sysfunc(round(42045*&tx_revalo_plaf.));   	/*plafond couple monoactif, 2 enfants*/
%let plaf_paje_1_old  =%sysfunc(round(47405*&tx_revalo_plaf.));   	/*plafond isol� ou couple bi-actif, 1 enfant*/
%let plaf_paje_2_old  =%sysfunc(round(54579*&tx_revalo_plaf.));   	/*plafond isol� ou couple bi-actif, 2 enfants*/
%let plaf_paje_sup_old=%sysfunc(round( 8609*&tx_revalo_plaf.));   	/*suppl�ment de plafond par enfant*/

%let plaf_paje_m1 =%sysfunc(round(30027*&tx_revalo_plaf.));   	  	/*plafond couple monoactif, 1 enfant*/
%let plaf_paje_m2 =%sysfunc(round(35442*&tx_revalo_plaf.));   	  	/*plafond couple monoactif, 2 enfants*/
%let plaf_paje_1  =%sysfunc(round(38148*&tx_revalo_plaf.));   	  	/*plafond isol� ou couple bi-actif, 1 enfant*/
%let plaf_paje_2  =%sysfunc(round(43563*&tx_revalo_plaf.));   	  	/*plafond isol� ou couple bi-actif, 2 enfants*/
%let plaf_paje_sup=%sysfunc(round( 5415*&tx_revalo_plaf.));   	  	/*suppl�ment de plafond par enfant*/

/*Paje � taux partiel*/
%let plaf_paje_m1_partiel =%sysfunc(round(35872*&tx_revalo_plaf.));	/*plafond couple monoactif, 1 enfant*/
%let plaf_paje_m2_partiel =%sysfunc(round(42341*&tx_revalo_plaf.));	/*plafond couple monoactif, 2 enfants*/
%let plaf_paje_1_partiel  =%sysfunc(round(45575*&tx_revalo_plaf.));	/*plafond isol� ou couple bi-actif, 1 enfant*/
%let plaf_paje_2_partiel  =%sysfunc(round(52044*&tx_revalo_plaf.));	/*plafond isol� ou couple bi-actif, 2 enfants*/
%let plaf_paje_sup_partiel=%sysfunc(round( 6469*&tx_revalo_plaf.));	/*suppl�ment de plafond par enfant*/

	/** Montant de l'allocation de base **/

/*D. 531-3 du code de la s�curit� sociale*/
%let taux_ABpaje=0.4595; 


/*************************************************************************************************************************************************************/
/*		b. Paje - Prime � la naissance							 		    																                 */
/*************************************************************************************************************************************************************/

/*D. 531-2 du code de la s�curit� sociale*/
%let taux_PNpaje=2.2975; 


/*************************************************************************************************************************************************************/
/*		c. Paje - CLCA (compl�ment libre choix d'activit�), d�sormais PreParEE							 		    																                 */
/*************************************************************************************************************************************************************/

/*D. 531-4 du code de la s�curit� sociale*/
%let taux_CLCA_plein=0.9662; /*taux plein*/
%let taux_CLCA_50=0.6246;    /*taux partiel <50*/
%let taux_CLCA_80=0.3603;    /*taux partiel 50-80*/


/*************************************************************************************************************************************************************/
/*				5- Compl�ment familial (CF)																								     				 */
/*************************************************************************************************************************************************************/

/*Plafond de ressources*/
%let plaf_cf_m3 =%sysfunc(round(37705*&tx_revalo_plaf.)); 	/*plafond pour 3 enfants couple monoactif*/
%let plaf_cf_3  =%sysfunc(round(46125*&tx_revalo_plaf.));  	/*plafond pour 3 enfants isol� ou couple bi-actif*/
%let plaf_cf_sup=%sysfunc(round( 6248*&tx_revalo_plaf.)); 	/*par enfant suppl�mentaire*/

/*R�forme du CF (plafond pour majoration +50%)*/
%let plaf_cf_m3_majo =%sysfunc(round(18856*&tx_revalo_plaf.)); 	/*plafond pour 3 enfants couple monoactif*/
%let plaf_cf_3_majo  =%sysfunc(round(23066*&tx_revalo_plaf.));  /*plafond pour 3 enfants isol� ou couple bi-actif*/
%let plaf_cf_sup_majo=%sysfunc(round( 3143*&tx_revalo_plaf.)); 	/*par enfant suppl�mentaire*/

/*Montant de l'allocation*/
%let tauxcf=0.4165;
%let tauxcf_majo=%sysevalf(0.5416+9/12*0.0417); /*revalorisation de la majo tous les ans le 1er avril jusqu'en 2018*/


/*************************************************************************************************************************************************************/
/*				6- Allocation de rentr�e scolaire (ARS)																					     				 */
/*************************************************************************************************************************************************************/

/*Plafond de ressources*/
%let plaf_ars_1  =%sysfunc(round(24404*&tx_revalo_plaf.));
%let plaf_ars_sup=%sysfunc(round(5632*&tx_revalo_plaf.));

/*Montant de l'allocation*/
/*D. 543-1 du code de la s�curit� sociale*/
%let taux_ars_6_10=0.8972; 
%let taux_ars_11_14=0.9467; 
%let taux_ars_15_18=0.9795;  


/*************************************************************************************************************************************************************/
/*				7- Allocation de soutien familial (ASF)																					     				 */
/*************************************************************************************************************************************************************/

%let tauxasf=%sysevalf(0.2589+9/12*0.0113); /*revalorisation de l'asf tous les ans le 1er avril jusqu'en 2018*/
%let tauxasf_sans_revalo=0.225; 			/*utilis�e dans le calcul de la base ressource du RSA, qui n'inclut pas la revalorisation exceptionnelle de l'ASF*/
%let montant_asf_erfs=%sysevalf(&tauxasf_sans_revalo.*&&bmaf&acour..);/*montant de l'ASF l'ann�e de l'ERFS 2013 : permet de recalculer le nombre d'enfants mois d'ASF per�ue*/ 



/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*                       												IV. Minima sociaux                 									 				 */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/


/*Les montants des minima sociaux sont exprim�s en moyenne annuelle*/

/*************************************************************************************************************************************************************/
/*				1- RSA																													     				 */
/*************************************************************************************************************************************************************/

/*Montant du RSA socle pour une personne seule*/
/*535.17 : montant du R0 du RSA au 1er janvier 2017*/
%let basersa&asuiv4.=%sysevalf(535.17*(3+&tx_revalo.*(5+4*1.0162))/12); /*1er avril : revalo classique. 1er septembre : revalorisation de 1,62%*/

/*Seuil de non versement*/
%let seuil_rsa=6;

/*Taux pour le RSA major� pour isolement (ex-API)*/
/*R. 262-1 du code de l'action sociale et des familles*/
%let taux_rsa_maji_pr=1.28412;     
%let taux_rsa_maji_pc=0.42804;     

/*Forfait logement : ann�e n (2017)*/ 
%let FL_1p=%sysevalf(&&basersa&asuiv4..*0.12*12);  		/*1 personne*/
%let FL_2p=%sysevalf(&&basersa&asuiv4..*0.16*1.5*12);  	/*2 personnes*/
%let FL_3p=%sysevalf(&&basersa&asuiv4..*0.165*1.8*12); 	/*3 personnes ou plus*/



/*************************************************************************************************************************************************************/
/*				2- Prime d'activit�																										     				 */
/*************************************************************************************************************************************************************/

/*Montant de la prime pour une personne seule (hors bonus)*/
%let basepa&asuiv4. =%sysevalf(524.68*(3+9*&tx_revalo.)/12); 

/*Seuil de non versement*/
%let seuil_pa=15;

/*Taux de cumul*/
%let tmipa=0.38 ;

/*Bonus individuel mensuel*/
%let maxbonus = %sysevalf(12.782/100*&&basepa&asuiv4..) ; 	/*12,782 % du R0: D. 843-2 Code de la s�curit� sociale*/
%let borne1_bonus = %sysevalf(59*&&smic_hor_brut&asuiv4.) ; 
%let borne2_bonus = %sysevalf(95*&&smic_hor_brut&asuiv4.) ; 

/*Forfait logement : ann�e n (2017)*/ 
%let FL_pa_1p=%sysevalf(&&basepa&asuiv4..*0.12*12);  /*1 personne*/
%let FL_pa_2p=%sysevalf(&&basepa&asuiv4..*0.16*1.5*12);  /*2 personnes*/
%let FL_pa_3p=%sysevalf(&&basepa&asuiv4..*0.165*1.8*12); /*3 personnes ou plus*/


/*************************************************************************************************************************************************************/
/*				3- Minimum vieillesse (ASPA) 																							     				 */
/*************************************************************************************************************************************************************/

/*Montant*/ 
/*Revalorisation au 1er avril 2017*/
%let minvi_1p=%sysevalf(800.8*(3+9*&tx_revalo.));  	/*en �/an*/ 
%let minvi_2p=%sysevalf(1243.24*(3+9*&tx_revalo.)); /*en �/an*/

/*Plafond*/
%let plaf_minvi_1p= &minvi_1p. ; 	/*en �/an*/
%let plaf_minvi_2p= &minvi_2p. ; 	/*en �/an*/


/*Abattement des revenus professionnels*/
/*Cr�� par d�cret en d�cembre 2014 : R. 815-29 du code de la s�curit� sociale*/
%let abat_celib = %sysfunc(round(%sysevalf(0.9*&&smic_hor_brut&asuiv4.*1820/12),0.01));
%let abat_couple = %sysfunc(round(%sysevalf(1.5*&&smic_hor_brut&asuiv4.*1820/12),0.01));


/*************************************************************************************************************************************************************/
/*				4- Allocation aux adultes handicap�s (AAH) 																				     				 */
/*************************************************************************************************************************************************************/

/*Montant*/
/*Revalorisation au 1er avril*/
%let aah=%sysevalf(808.46*(3+9*&tx_revalo.)); 	/*en �/an*/ 

/*Plafond de ressources*/
%let plaf_aah_1p= &aah. ;                       /*pour une personne seule */
%let plaf_aah_2p=%sysevalf(2*&plaf_aah_1p.);    /*pour couple*/
%let plaf_aah_sup=%sysevalf(0.5*&plaf_aah_1p.); /*par enfant � charge*/


/*************************************************************************************************************************************************************/
/*				5- CMUc 																												     				 */
/*************************************************************************************************************************************************************/

/*Plafond en revenu par mois en moyenne annuelle*/
/*Revalorisation au 1er avril */
%let plaf_cmuc=8653.16 ;
%let plaf_cmuc1 = %sysevalf(&plaf_cmuc.*(3+9*&tx_revalo.)/12) ; 
%let plaf_cmuc2 = %sysevalf(1.5*&plaf_cmuc.*(3+9*&tx_revalo.)/12); 
%let plaf_cmuc3 = %sysevalf(1.8*&plaf_cmuc.*(3+9*&tx_revalo.)/12); 
%let plaf_cmuc4 = %sysevalf(2.1*&plaf_cmuc.*(3+9*&tx_revalo.)/12); 
%let plaf_cmuc_supp = %sysevalf(0.4*&plaf_cmuc.*(3+9*&tx_revalo.)/12); 


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/
