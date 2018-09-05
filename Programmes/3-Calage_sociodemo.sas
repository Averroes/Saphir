

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 3                                         						          */
/*                           									Calage sur marge de l'ERFS 2017															      */
/**************************************************************************************************************************************************************/


libname calmar "&chemin_Saphir_2017.\Programmes\Macros";
option mstored sasmstore=calmar; 	/*stockage de la macro Calmar*/

/**************************************************************************************************************************************************************/
/* Pour prendre en compte les �volutions structurelles ayant eu lieu entre 2013 et 2017, l��chantillon de l�EFRS 2013 est redress� par un calage. La m�thode  */
/* du calage sur marges consiste � modifier les poids des personnes r�pondantes de telle sorte que le total de certaines variables estim� � partir des 		  */
/* r�pondants de l��chantillon soit �gal au total connu par ailleurs sur une population de r�f�rence (les � marges �). 										  */
/* Le calage est r�alis� au niveau m�nage. Ce programme : 																									  */
/* 			1- D�finit la macro %creavar qui permet de constuire les tables de calage        																  */
/* 			2- Cr�e la table initiale � caler          																									   	  */
/* 			3- D�finit la macro %calage pour faire la repond�ration de l'ERFS � partir des marges renseign�es dans le fichier excel							  */
/* 			4- Effectue un calage sur marges T4 2017																										  */ 
/* 			5- Cr�e une table de sortie avec les poids  																									  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											I. Macro %CREAVAR	         	           						      					  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Macro cr�ant les variables n�cessaires au calage au niveau individuel       																     			  */
/* Cette macro est ex�cut�e sur table individu ERFS, EEC 2014 et EEC 2015            	   																	  */
/**************************************************************************************************************************************************************/
/* tabin = table en entr�e (table individu)                                    																				  */
/* tabsor = table en sortie (table individu)                                   																			      */
/* ident_men= = identifiant m�nage                                            																				  */
/**************************************************************************************************************************************************************/

%macro creavar(tabin=, tabsor1=, tabsor2=, ident_men=, poids=); 

proc sort data=&tabin.; by &ident_men. ag ; run;

data 	&tabsor1. (keep=&ident_men. &poids. ex: act1-act6 cs1-cs4 cat1-cat4 cdd agseniors: agenf: aghom: agfem: lpr:) 
		&tabsor2. (keep=&ident_men. &poids. ex: tymen locat adult enf enf3 enf6 nbenf3 nbenf6);
set &tabin. (keep=&ident_men. &poids.  ex: noi sexe matri ag naia naim lpr: contra officc acteu acteu6 titc tppred cstot stc logt annee); 
by &ident_men.;


if input(ag,3.)<18 & matri='' then matri='1';

 	retain adult enf enf3 enf6 attrib1 attrib2 menplus60 cat1-cat4; 
	if first.&ident_men. then do; adult=0; enf=0; enf3=0; enf6=0; attrib1=0; attrib2=0; menplus60=0; cat1=0; cat2=0; cat3=0; cat4=0; end;

	if lprm='3' & input(ag,3.)<=20 & matri='1' then enf=enf+1;
	else adult=adult+1;
	if lprm='3' & input(ag,3.)<=3 & matri='1' then enf3=enf3+1;
	if lprm='3' & input(ag,3.)<=6 & matri='1' then enf6=enf6+1;
	
	attrib1=attrib1+(lprm='1' & sexe='1');
	attrib2=attrib2+(lprm='2' & sexe='2');
	menplus60=menplus60+(input(ag,3.)>=60);

	/*Nombre d'agriculteurs, ind�pendants, salari�s et retrait�s*/ 
	cat1=('11'<=cstot<='13') ;										      /*agriculteurs*/
	cat2=(cstot in ('21','22','31') & stc='1') ;					      /*ind�pendants*/
	cat3=(cstot<='69'); 									     		  /*salari�s*/
	cat4=(('71'<=cstot<='78' & input(ag,3.)>=53) ! input(ag,3.)>=65) ;    /*retrait�s*/

	/*Personnes �g�es par tranches d'�ge*/
	agseniors1=(60<=input(ag,3.)<65);
	agseniors2=(65<=input(ag,3.)<70);
	agseniors3=(70<=input(ag,3.)<75);
	agseniors4=(75<=input(ag,3.)<80);
	agseniors5=(80<=input(ag,3.));

	/*Enfants par tranches d'�ge*/
	agenf1=(0<=input(ag,3.)<3);
	agenf2=(3<=input(ag,3.)<6);
	agenf3=(6<=input(ag,3.)<10);
	agenf4=(10<=input(ag,3.)<15);
	agenf5=(15<=input(ag,3.)<20);
	agenf6=(20<=input(ag,3.)<25);

	/*Croisement des variables sexe*age pour les adultes d'�ge interm�diaire*/
	aghom1=(sexe="1")*(25<=input(ag,3.)<35);
	aghom2=(sexe="1")*(35<=input(ag,3.)<50);
	aghom3=(sexe="1")*(50<=input(ag,3.)<60);

	agfem1=(sexe="2")*(25<=input(ag,3.)<35);
	agfem2=(sexe="2")*(35<=input(ag,3.)<50);
	agfem3=(sexe="2")*(50<=input(ag,3.)<60);

	/*Identification de l'activit� et du ch�mage parmi les adultes de 20-59 ans*/
	act1=(20<=input(ag,3.)<60)*(officc='1');												   		/*inscrit comme demandeur d'emploi*/
	act2=(20<=input(ag,3.)<60)*((acteu='1' or titc='1')&(tppred ne '2')&(act1 ne 1)); 				/*actif occup� � temps plein : TPPRED = temps de travail redress�*/
																									/*titc=1 : les �l�ves fonctionnaires sont rajout�s car r�mun�r�s*/
	act3=(20<=input(ag,3.)<60)*((acteu='1' or titc='1')&(tppred='2')&(act1+act2 ne 1));				/*actif occup� � temps partiel*/	
	act4=(20<=input(ag,3.)<60)*((sexe='2' & lprm in ('1','2') & enf>0) & (sum(of act1-act3)=0));    /*femmes inactives avec enfant */
	act5=(20<=input(ag,3.)<60)*((input(ag,3.)<25) & (sum(of act1-act4)=0)); 					   	/*inactifs de moins 25 ans : approximativement les etudiants*/
	act6=(20<=input(ag,3.)<60)*(sum(of act1-act5)=0);											   	/*autres inactifs de moins de 60 ans*/

	/*Cat�gories socioprofessionnelles parmi les actifs occup�s et les ch�meurs de 20-59 ans*/
	cs1=(act1+act2+act3)*(substr(cstot,1,1)='3' ! cstot in ('23','74'));				/*cadres et chefs d'entreprise*/
	cs2=(act1+act2+act3)*(substr(cstot,1,1)='4' ! cstot in ('22','75'));				/*professions interm�diaires et commercants*/
	cs3=(act1+act2+act3)*(('52'<=cstot<='54') ! cstot in ('21','62','64','65','77')); 	/*employ�s qualifi�s, artisans, ouvriers qualifi�s sauf ouvriers qualifi�s de l'artisanat, anciens employ�s*/
	cs4=(act1+act2+act3)*(sum(of cs1-cs3)=0); 										  	/*ouvriers et employ�s, ouvriers agricoles, agriculteurs, divers autres*/
	
	/*Contrat � dur�e d�termin�e*/
	cdd=(contra in ('2','3','4'));

	output &tabsor1.  ;

	/*Typologie des m�nages*/
	if last.&ident_men. then do;
		if enf>0 then menplus60=0; /*pour les menages avec un enfant, on ne distingue pas plus et moins de 60 ans */
		coup=(attrib1=1 & attrib2=1);

		if not menplus60 & not coup & not enf then tymen=1;	/*personnes seules et m�nages complexes moins 60 ans sans couple et sans enfant*/
		else if not menplus60 & coup & not enf then tymen=2;/*couples sans enfant*/
		else if coup & enf=1 then tymen=3;					/*couples avec 1 enfant*/
		else if coup & enf=2 then tymen=4;					/*couples avec 2 enfants*/
		else if coup & enf>=3 then tymen=5;					/*couples avec au moins 3 enfants*/
		else if enf then tymen=6;							/*parents isol�s*/
		else if menplus60 & not coup then tymen=7;			/*personnes seules et m�nages complexes comprenant un individu de plus de 60 ans*/
		else if menplus60 & coup then tymen=8;				/*couples (sans enfant) comprenant un individu de plus de 60 ans*/

		/*M�nage avec au moins 1 enfant de moins de 3 ans ou de moins de 6 ans*/
		nbenf3=(enf3>0); nbenf6=(enf6>0); 

		
		/*Statut d'occupation du logement : utilisation de la variable LOGT, ancienne variable SO compl�t�e apr�s la refonte de l'EEC 2013*/
		/*La modalit� "locataires d'un logement lou� vide" comprend tous les locataires. Les viagers sont dans les propri�taires.
		Les personnes log�es � titre gratuit figurent dans "Autres"*/
		locat=(logt in ('3','4','5')); 

		output &tabsor2.  ;
	end;
run;
%mend;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											II. Table ERFS � caler	                 			 						   			  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/ 
/* Cr�ation des variables et passage au niveau menage         												 												  */
/* Cr�ation de la table MEN_INPUT                      											  															  */
/**************************************************************************************************************************************************************/


%creavar(tabin=saphir.irf&acour.e&acour.t4c, tabsor1=ind_input, tabsor2=men_input, ident_men=ident&acour., poids=wprm);

%let VarCalInd=agseniors1-agseniors5 agenf1-agenf6 aghom1-aghom3 agfem1-agfem3 act1-act6 cs1-cs4 cat1-cat4 cdd ;
proc means data=ind_input  noprint nway;
	class ident&acour.;
	var &VarCalInd. ;
	output out=sor (drop = _TYPE_ _FREQ_ ) sum=;
run;

data table_calage (drop=ex: logtm); merge men_input sor 
saphir.menage&acour._r&asuiv3. (keep=ident&acour. zsalm&asuiv3. zchom&asuiv3. zrstm&asuiv3. zragm&asuiv3. zricm&asuiv3. zrncm&asuiv3.) erfs.menage&acour. (keep=ident&acour. logtm); by ident&acour.;
run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       										III. Calcul des marges de calage	                 						    	 		  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*                           										 MACRO %CALAGE                                 							   			      */
/* Cette macro calage permet de faire la repond�ration de l'ERFS en utilisant les marges issues du fichier excel FILENAME, � l'onglet correspondant � la      */
/* bonne ann�e.					  																															  */
/*																																							  */
/* Liste des param�tres : 																																	  */
/* 		- LO et UP : ratios minimal et maximal entre le poids de sortie et le poids initial																	  */
/* 		- POIDS : nom de la variable de pond�ration en entr�e                     																			  */
/* 		- POIDSFIN : nom de la variable de pond�ration modifi�e      																						  */
/**************************************************************************************************************************************************************/


%macro calage(FILENAME,ANNEE,LO,UP,POIDS,POIDSFIN);

/*Les marges utilis�es par d�faut si l'utilisateur ne renseigne pas les marges de calage sont les marges endog�nes de l'ERFS*/
%if &calage_par_defaut.= 1 %then %do ;
	options noxwait noxsync;
	%sysexec "&chemin_Saphir_2017.\parametres.xls";

	data _null;
		x=sleep(5);
	run;

	proc means data=table_calage sum; var 
	agenf1 agenf2 agenf3 agenf4 agenf5 agenf6 aghom1 aghom2 aghom3 agfem1 agfem2 agfem3 agseniors1 agseniors2 agseniors3 agseniors4 agseniors5
	act1 act2 act3 act4 act5 act6 cat1 cat2 cat3 cat4 cdd nbenf3 nbenf6;
	output out=marges_endogenes1 sum=;
	weight wprm;
	run;
	proc transpose data=marges_endogenes1 out=marges_endogenes1_;
	var agenf1 agenf2 agenf3 agenf4 agenf5 agenf6 aghom1 aghom2 aghom3 agfem1 agfem2 agfem3 agseniors1 agseniors2 agseniors3 agseniors4 agseniors5
	act1 act2 act3 act4 act5 act6 cat1 cat2 cat3 cat4 cdd nbenf3 nbenf6;
	run;
	filename tr dde "excel|calage_&annee.!L2C5:L31C5" notab; data _null_; file tr;
	set marges_endogenes1_;
	put col1 ;
	run;

	proc freq data=table_calage; tables tymen / out=marges_endogenes2; weight wprm; run;
	proc transpose data=marges_endogenes2 out=marges_endogenes2_;
	var count;
	run;
	filename tr dde "excel|calage_&annee.!L32C5:L32C5" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col1    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C6:L32C6" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col2    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C7:L32C7" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col3    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C8:L32C8" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col4    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C9:L32C9" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col5    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C10:L32C10" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col6    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C11:L32C11" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col7    ;
	run;
	filename tr dde "excel|calage_&annee.!L32C12:L32C12" notab; data _null_; file tr;
	set marges_endogenes2_;
	put col8    ;
	run;


	proc means data=table_calage sum; var locat ZSALM16 ZCHOM16 ZRSTM16 ZRAGM16 ZRICM16 ZRNCM16;
	output out=marges_endogenes3 sum=;
	weight wprm;
	run;
	proc transpose data=marges_endogenes3 out=marges_endogenes3_;
	var locat ZSALM16 ZCHOM16 ZRSTM16 ZRAGM16 ZRICM16 ZRNCM16;
	run;
	filename tr dde "excel|calage_&annee.!L33C5:L39C5" notab; data _null_; file tr;
	set marges_endogenes3_;
	put col1 ;
	run;

	filename cmds dde 'excel|system';
	data _null_;
		file cmds;
		put '[error(false)]';
		put '[Save()]';
		put '[Quit()]';
	run;

	data _null;
		x=sleep(5);
	run;
%end;

proc import OUT= WORK.MARGE(keep=var n mar1-mar8)  DATAFILE=&FILENAME. dbms=xls REPLACE; sheet="calage_&annee."; RUN;
data marge ; set marge ; if var in ("cs4" "act6") then delete ; run ; /*pour �viter la colin�arit�*/

/*Repond�ration pour avoir le bon nombre de m�nages dans la table de d�part*/
proc sql noprint; select sum(MAR1, MAR2, MAR3, MAR4, MAR5, MAR6, MAR7, MAR8) into : pop_&asuiv. from marge where var="tymen"  ;  quit; 
proc sql noprint; select sum(wprm) into : pop_&acour. from table_calage ;  quit;
data table_calage; set table_calage; poiinit=wprm*%sysevalf(&&&pop_&asuiv./&&&pop_&acour.); run; 


%CALMAR(DATA=table_calage,DATAMAR=marge,M=3,LO=&LO.,UP=&UP.,IDENT=ident&acour.,POIDS=&POIDS.,POIDSFIN=&POIDSFIN.,DATAPOI=poi&annee.,PCT=NON,OBSELI=oui, NOTES=oui);

%mend;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       										IV. Calage sur marges sur le T4 2017	                 								      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%calage(FILENAME="&chemin_Saphir_2017.\parametres.xls",
		ANNEE=&asuiv4.,
		LO=0.60,	/*param�tre � renseigner par l'utilisateur*/
		UP=1.25,	/*param�tre � renseigner par l'utilisateur*/
		POIDS=poiinit,
		POIDSFIN=wprm&asuiv4.);



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       								V. Cr�ation d'une table de sortie avec les poids	              								      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

data saphir.pond (compress = yes);
merge erfs.menage&acour. (keep = ident&acour. wprm) poi&asuiv4.;
by ident&acour.;
run;


/*Nettoyage de la work*/
proc datasets library=work kill; run; quit;
/*Pour lib�rer la library qui comprend les macros*/
LIBNAME tmp "%SYSFUNC(GETOPTION(work))" ACCESS=temp ; OPTION MSTORED sasmstore=tmp ;
%MACRO rien / STORE ; %MEND rien ;
LIBNAME calmar CLEAR ;


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/
