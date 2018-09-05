

/**************************************************************************************************************************************************************/
/*                                										SAPHIR E2013 L2017                                         							  */
/*                                     										PROGRAMME 1                                            							  */
/*       									Correction des donn�es de l'ERFS 2013 et cr�ation de variables auxiliaires           							  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Le mod�le Saphir 2017 s'appuie sur l'Enqu�te Revenus Fiscaux et Sociaux (ERFS) 2013 de l'Insee. L'ERFS 2013 consiste en l'appariement de trois sources :   */
/*		- l'Enqu�te Emploi en Continu (EEC) du 4e trimestre 2013 : l'EEC comprend des informations individuelles sur la situation professionnelles des		  */
/*		  individus �g�s de plus de 15 ans ;																												  */
/*		- des fichiers fiscaux de la DGFip qui contiennent toutes les informations de la d�claration fiscale 2014 sur les revenus 2013 ;					  */
/*		- des fichiers sociaux issus de la Cnaf, de la MSA et de la Cnav qui contiennent les montants des prestations per�ues en 2013 ;						  */
/*																																							  */
/* Sont conserv�s dans l'�chantillon ERFS les m�nages pour lesquels un appariement a pu �tre r�alis� soit avec les donn�es fiscales soit avec les donn�es     */
/* sociales, ainsi que les m�nages dont la personne de r�f�rence est �tudiante. Comme l'EEC, l'ERFS porte sur les m�nages ordinaires de France m�tropolitaine.*/
/*																																							  */ 
/* Ce premier programme exploite et organise les donn�es de l'ERFS pour cr�er les tables de base au niveau individuel, au niveau du foyer et du m�nage qui    */
/* seront exploit�es par le mod�le Saphir.																													  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                      												 I. Table foyer					                							          */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

data foyer&acour._cor;
set erfs.foyer&acour.;

if   sif="SIF M1970 1969 000P0000  P 000000000000000000000000000    F10G00R00J01N00H00I00P00 00 00"
then sif="SIF M1970 1969 000P0000  P 000000000000000000000000000    F00G00R00J01N00H00I00P00 00 00";

if	 sif="SIF D1955 9999 0000000     000000000000000000000000000    F00G00R00J01N00H00I00P00 00 00"
then sif="SIF D1955 9999 00000000    000000000000000000000000000    F00G00R00J01N00H00I00P00 00 00";

if	 sif="SIF M1981 1980 0000000     000000000000000000000000000    F02G00R00J00N00H00I00P00 00 00"
then sif="SIF M1981 1980 00000000    000000000000000000000000000    F02G00R00J00N00H00I00P00 00 00";

if	 sif="SIF D1956 9999 00L0000   L 000000000000000000000000000    F00G00R00J00N00H00I00P00 00 00"
then sif="SIF D1956 9999 00L00000  L 000000000000000000000000000    F00G00R00J00N00H00I00P00 00 00";


declar=compress(declar) ;
longueur=length(anaisenf);
nbpac=round(longueur/5,1);


if nbpac=0 then do;		/*revenus dans les cases C ou D sans personne � charge (PAC) : 0 obs dans ERFS 2013*/
	_1aj=_1aj+_1cj+_1dj;
	_1cj=0;
	_1dj=0;
	_1ap=_1ap+_1cp+_1dp;
	_1cp=0;
	_1dp=0;
	_1as=_1as+_1cs+_1ds;
	_1cs=0;
	_1ds=0;
end;
if nbpac=1 then do;		/*revenus dans les cases D avec une seule PAC : 0 obs dans ERFS 2013*/
	_1cj=_1cj+_1dj;
	_1dj=0;
	_1cp=_1cp+_1dp;
	_1dp=0;
	_1cs=_1cs+_1ds;
	_1ds=0;
end;

run;
data saphir.foyer&acour.;set foyer&acour._cor;run;
proc sort data=saphir.foyer&acour. nodupkey;by ident&acour. idec&acour.;run; 


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                      											II. Table individus					                							          */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*              							Correction des donn�es de l'enqu�te Emploi et cr�ation de variables utiles         			  					  */
/*                                                               						      																  */
/* Table utilis�e : irf13e13t4 de la librairie ERFS2013          							  																  */
/* Table cr��e : irf13e13t4c dans la librairie SAPHIR            							  																  */
/* Remarque : champ restreint par rapport � irf13e13t4(seuls les individus ERFS sont conserv�s)     														  */
/**************************************************************************************************************************************************************/

/*R�gime micro : montant minimum de l'abattement*/
%let E2000=305;


/**************************************************************************************************************************************************************/
/*				1- Cr�ation d'une table individuelle avec les individus appartenant au champ ERFS      									     				  */
/**************************************************************************************************************************************************************/

proc sort data=erfs.irf&acour.e&acour.t4 nodupkey out=irf&acour.e&acour.t4; by ident&acour. noi; run;
proc sort data=erfs.indivi&acour. nodupkey out=indivi&acour.; by ident&acour. noi; run; 

data corr_ind (drop= noienf10 noienf11 noienf12 noienf13 noienf14); 
length IDENT&acour. $8. NOI $2.;
merge irf&acour.e&acour.t4(in=a) indivi&acour. (keep = ident&acour. noi zragi zrici zrnci zperi zsali zrsti zchoi declar1 declar2 persfip  wprm in=b);
by ident&acour. noi;
if a & b then output corr_ind;
run;


/**************************************************************************************************************************************************************/
/*				2- Cr�ation de variables, changements de format, corrections	           												     				  */
/**************************************************************************************************************************************************************/

data corr_ind (rename= (naim2=naim naia2=naia));set corr_ind;

/*COLLA, COLLM, COLLJ : date de collecte : en 2013, la variable datcoll dispara�t et est remplac�e par DATQI qui est la date de collecte au niveau individuel*/
if datqi ^in (' ' '00000000') then do;
	colla=input(substr(datqi,1,4),4.);  /*annee semaine de collecte*/
	collm=input(substr(datqi,5,2),2.);  /*mois semaine de collecte*/
	collj=input(substr(datqi,7,2),2.);  /*jour semaine de collecte*/
end;
else do; /*si datqi n'est pas renseign�, on fait appel � datdeb (d�but de la semaine de r�f�rence)*/
	colla=input(substr(datdeb,1,4),4.); /*annee semaine de collecte*/
	collm=input(substr(datdeb,5,2),2.); /*mois semaine de collecte*/
	collj=input(substr(datdeb,7,2),2.); /*jour semaine de collecte*/
end;

/*Changement format noicon noimer noiper noienf01-noienf09*/
array noi_(*) $2. NOICON NOIMER NOIPER NOIENF01-NOIENF09;
array noic_(*) $2. NOICONC NOIMERC NOIPERC NOIENFC01-NOIENFC09; 
do i=1 to dim(noi_);
	noic_{i}=compress(noi_{i});
	if length(noic_{i})=1 & noic_{i} ne ' ' then noic_{i}=compress('0'!!noi_{i});
end;
drop noicon noimer noiper noienf01-noienf09 i;

/*NAIA, NAIM : changement format naia naiam*/
naia2=input(naia,4.);
naim2=input(naim,2.);
drop naia naim;

/*AGENQ : age � la date de l'enqu�te en ann�e */
if naim2<collm then agenq=colla-naia2;
else if naim2=collm then do;
	if naia2=colla then do;
		agenq=0;
	end;
	else do;
		if collj>15 then agenq=colla-naia2;	/*on suppose que les gens sont n�s le 15 en moyenne*/
		else agenq=colla-naia2-1;
	end;
end;
else if naim2>collm then agenq=colla-naia2-1;

/*NOINDIV : concat�nation de l'identifiant du m�nage et de celui de l'individu*/
noindiv=compress(ident&acour.!!noi);
run;

/*RGMEN : rang dans le m�nage = classement par �ge*/
proc sort data=corr_ind; by ident&acour. naia naim; run;
data corr_ind;set corr_ind;
by ident&acour. naia naim;
retain rgmen 0;
if first.ident&acour. then rgmen=1;
else rgmen=rgmen+1;run;


/**************************************************************************************************************************************************************/
/*				3- Correction et remplissage des NOICON, NOIPER NOIMER, NOIENF	           												     				  */
/**************************************************************************************************************************************************************/



/**************************************************************************************************************************************************************/
/*		a. Ajout d'une s�quence NOIMEN : s�quence des noi du m�nage																 		                      */
/**************************************************************************************************************************************************************/

proc sort data=corr_ind; by ident&acour. noi; run;
proc transpose data=corr_ind out=corr_ind2 (drop=_NAME_ _LABEL_);by ident&acour.;var noi;run; /*table avec 1 ligne=1 m�nage et l'ensemble des noi de ce m�nage*/
data corr_ind2 (keep = ident&acour. noimen);set corr_ind2;	/*NOIMEN : s�quence des NOI du m�nage*/
noimen=compress(col1!!col2!!col3!!col4!!col5!!col6!!col7!!col8!!col9!!col10!!col11);run;
data corr_ind;merge corr_ind corr_ind2;by ident&acour.;run;	/*on rajoute la s�quence � la table individu*/
proc datasets library=work;delete corr_ind2;run;quit;


/**************************************************************************************************************************************************************/
/*		a. Corrections des NOI quand incoh�rence																				 		                      */
/**************************************************************************************************************************************************************/

			/*** On v�rifie que le NOI du d�clarant appartient toujours aux NOI du m�nage (NOIMEN)***/
data corr_ind (rename= (NOICONC=NOICON NOIMERC=NOIMER NOIPERC=NOIPER NOIENFC01-NOIENFC09=NOIENF01-NOIENF09));set corr_ind;

		/** Correction des NOICONC, NOIPERC, NOIMERC, NOIENFC **/
/*i - Si les NOI ne sont pas dans la liste des NOI du m�nage, on les met � blanc*/
    array noi_ $2. noiconc noiperc noimerc noienfc01-noienfc09;
    pb=0;
    do i=1 to dim(noi_);
	    if noi_{i} ne ' ' & index(noimen,noi_{i})=0 then do;
	    noi_{i} =' ';
	    pb=1;
	    end;
    end;
/*ii - Si personne seule ou couple sans enfant => NOIENF1=' ' NOIPER= ' ' NOIMER=' '*/
    array noipme_ $2. noiperc noimerc noienfc01-noienfc09;
    pb2=0;
    if (typmen7='1' & nbind=1) ! (typmen7='3' & nbind=2) then do;
	   do i=1 to dim(noipme_);
		   if noipme_{i} ne ' ' then do;
           noipme_{i}=' ';
		   pb2=1;
		   end;
	   end;
    end;
/*iii - Si personne PR ou conjoint de PR d'une famille => NOIPER= ' ' NOIMER=' '*/
	pb3=0 ;
	if typmen7 in('1','2','3','4') & lprm in ('1','2') then do;
	   noiperc=' ';
	   noimerc=' ';
	   pb3=1;
    end;      
		  
/*iv -Correction NOIENF quand correspondent � NOI ou NOICON *//*=> on fait confiance au NOICON et NOI => mise � blanc*/
    pb4=0;
    array noienf_ $2. noienfc01-noienfc09;
    do i=1 to dim(noienf_);
	   if noienf_{i} ne ' ' & (noienf_{i}=noi ! noienf_{i}=noiconc) then do ;  noienf_{i}=' ';  pb4=1 ; end ;
    end;
    drop i;
run;


			/*** Remplissage du NOIPER ***/

/*Quand il y a dans le m�nage une personne de sexe masculin ayant des enfants dans le m�nage --> on le consid�re comme le p�re*/

		/** NOIPER : table avec une ligne par p�re **/
data noiper (keep = ident&acour. noienf01-noienf09 noiper2 );set corr_ind;
if sexe='1' & (noienf01 ne ' ' ! noienf02 ne ' ' ! noienf03 ne ' ' ! noienf04 ne ' ' ! noienf05 ne ' ' ! noienf06 ne ' ' ! 
noienf07 ne ' ' ! noienf08 ne ' ' ! noienf09 ne ' '); /*selection des personnes de sexe masculin avec enfants*/
rename noi=noiper2; /*NOIPER2 : noi de pere*/
run;

		/** NOIPER2 : table avec une ligne par enfant **/
proc sort data=noiper; by ident&acour. noiper2; run;
proc transpose data=noiper out=noiper2 (drop=_NAME_ rename=(col1=noi)); by ident&acour. noiper2; var noienf01-noienf09; run;
data noiper2;set noiper2;if noi=' ' then delete;run;

		/** On merge avec CORR_IND et on remplit NOIPER par NOIPER2 si NOIPER est manquant **/
proc sort data=corr_ind ; by ident&acour. noi; run;
proc sort data=noiper2 noduprecs ; by ident&acour. noi; run;
data corr_ind (drop= noiper2);
merge corr_ind noiper2 ;
by ident&acour. noi;
if noiper=' ' & noiper2 ne ' ' then do ;
noiper=noiper2; 
pere_manq=1;
end;
run;
proc datasets library=work;delete noiper noiper2;run;quit;


			/*** Remplissage du NOIMER ***/

/*Quand personne de sexe f�minin ayant des enfants dans le m�nage --> on la consid�re comme la m�re*/

		/** NOIMER : table avec une ligne par m�re **/
data noimer (keep = ident&acour. noienf01-noienf09 noimer2 );set corr_ind;
if sexe='2' & (noienf01 ne ' ' ! noienf02 ne ' ' ! noienf03 ne ' ' ! noienf04 ne ' ' ! noienf05 ne ' ' ! noienf06 ne ' ' ! 
noienf07 ne ' ' ! noienf08 ne ' ' ! noienf09 ne ' ' ); /*selection des personnes de sexe feminin ayant des enfants dans le m�nage*/
rename noi=noimer2;	/*NOIMER2 : on renomme leur noi comme noi de la m�re*/
run;

		/** NOIMER2 : table avec une ligne par enfant **/
proc sort data=noimer; by ident&acour. noimer2; run;
proc transpose data=noimer out=noimer2 (drop=_NAME_ rename=(col1=noi)); by ident&acour. noimer2; var noienf01-noienf09; run;
data noimer2;set noimer2;if noi=' ' then delete;run;

		/** On merge avec CORR_IND et on remplit NOIMER par NOIMER2 si NOIMER est manquant **/
proc sort data=corr_ind; by ident&acour. noi; run;
proc sort data=noimer2  noduprecs; by ident&acour. noi; run;
data corr_ind (drop = noimer2);
merge corr_ind noimer2 ;
by ident&acour. noi;
if noimer=' ' & noimer2 ne ' ' then do; 
noimer=noimer2;
mere_manq=1;
end;run;
proc datasets library=work;delete noimer noimer2 ;run;quit;


			/*** Remplissage du NOIMER quand la personne de sexe f�minin est en cong� maternit� et que l'enfant est n� dans l'ann�e ***/

data noicongmat;
merge corr_ind (keep=ident&acour. noi sexe)
erfs_c.icomprf&acour.e&acour.t1 (keep =ident&acour. noi rabs rename=(rabs=rabs13_t1))
erfs_c.icomprf&acour.e&acour.t2 (keep =ident&acour. noi rabs rename=(rabs=rabs13_t2))
erfs_c.icomprf&acour.e&acour.t3 (keep =ident&acour. noi rabs rename=(rabs=rabs13_t3))
irf&acour.e&acour.t4 (keep =ident&acour. noi rabs rename=(rabs=rabs13_t4));
by ident&acour. noi;
if (sexe='2')&((rabs13_t1='3')|(rabs13_t2='3')|(rabs13_t3='3')|(rabs13_t4='3'));
rename noi=noimat;
drop rabs13: sexe;
run;
data corr_ind;merge corr_ind noicongmat;by ident&acour.;
if noimer=' ' & noimat ne ' ' & ag<2 then do;
noimer=noimat;pb5=1;end;drop noimat;run;

proc datasets library=work;delete noicongmat;run;quit;


			/*** Remplissage du NOICON ***/

		/** Cas 1 - on a l'information pour au moins un conjoint **/

/*Quand la personne est conjoint d'une personne du m�nage*/
/*NOICON : table avec une ligne par personne avec un conjoint*/
data noicon ;set corr_ind (keep = ident&acour. noicon noi);if noicon ne ' ' ;rename noi=noicon2 noicon=noi;run;	/*NOICON => NOI et NOI => NOICON2 : on part de 
																								ceux pour lesquels on a un noi pour retrouver le noi du conjoint*/
proc sort data=corr_ind; by ident&acour. noi; run;
proc sort data=noicon; by ident&acour. noi; run;
data corr_ind (drop = noicon2);merge corr_ind noicon ;by ident&acour. noi;if noicon=' ' & noicon2 ne ' ' then noicon=noicon2; run;
proc datasets library=work;delete noicon;run;quit;

		/** Cas 2 - on n'a aucune information **/

/*S�lection des personnes en couple dont conjoint pas renseign�*/
data conj (keep = ident&acour. noi); set corr_ind;if lprm in('1','2') & typmen7 in('3','4') & noicon=' '; run; 
proc sql noprint; select distinct count(*) into: nobs from conj; quit; 
%macro conj;
%if &nobs.>0 %then %do;
proc transpose data=conj out=conj2 (drop=_NAME_ _label_); by ident&acour.; var noi; run;
data n1;set conj2;rename col1=noi col2=noicon;run; 
data n2;set conj2;rename col1=noicon col2=noi;run;
data n;set n1 n2;run;
proc sort data=n; by ident&acour. noi; run;
data corr_ind;merge corr_ind n;by ident&acour. noi; run;
proc datasets library=work;delete conj conj2 n n1 n2;run;quit;
%end;
%mend; %conj;


			/*** Remplissage du NOIENF ***/

/*Quand la personne est enfant d'une personne du m�nage*/

		/** NOIENFP : table avec une ligne par enfant (d'un p�re) **/
/*S�lection des personnes dont le NOIPER est renseign� = p�re dans le m�nage*/
data noienfp (keep = ident&acour. noienf2 noi);set corr_ind;if noiper ne ' ' ;rename noi=noienf2 noiper=noi;run;

		/**NOIENFM : table avec une ligne par enfant (d'une m�re) **/
/*S�lection des personnes dont le NOIMER est renseign� = m�re dans le m�nage*/
data noienfm (keep = ident&acour. noienf2 noi);set corr_ind;if noimer ne ' ' ;rename noi=noienf2 noimer=noi;run;

		/** NOIENF : table avec une ligne par enfant et par parent **/
data noienf;set noienfp noienfm;run;
proc sort data=noienf; by ident&acour. noi noienf2; run;
proc transpose data=noienf out=noienf2 (drop=_LABEL_ _NAME_ ) prefix=noienfa; by ident&acour. noi; var noienf2; run;
data corr_ind (drop = noienfa1-noienfa9 pb: listenf listenfa);merge corr_ind noienf2;by ident&acour. noi;
listenf=compress(noienf01!!noienf02!!noienf03!!noienf04!!noienf05!!noienf06!!noienf07!!noienf08!!noienf09);
listenfa=compress(noienfa1!!noienfa2!!noienfa3!!noienfa4!!noienfa5!!noienfa6!!noienfa7!!noienfa8!!noienfa9);
pb=(listenf ne listenfa);	/*PB : indicatrice qui vaut 1 si la liste des enfants affect�s � l'individu diff�re de la liste des enfants reconstitu�e*/
pb1=0;						/*PB1 : indicatrice qui vaut 1 si un NOIENF affect� � l'individu n'appartient pas � la liste des enfants reconstitu�e*/
%macro noienf;
%do i=1 %to 9;
	pb1&i.=(noienf0&i. ne ' ' & index(listenfa,noienf0&i.)=0);
	pb1=pb1+pb1&i.;
%end;
%do i=1 %to 9;	noienf0&i.=noienfa&i.;%end;	/*on remplace NOIENF0i par NOIENFAi pour pallier les trous et le mauvais ordre*/
%mend;
%noienf;
run;
proc datasets library=work;delete noienf noienf2 noienfp noienfm;run;quit;


			/*** Ajout du NOI des enfants du conjoint ***/

		/**ENFCONJ : table avec une ligne par conjoint **/

/*S�lection des individus qui ont un conjoint*/
data enfconj (keep = noindiv noienfc1-noienfc9);
set corr_ind (drop = noi noiper noimer noindiv);if noicon ne ' ';
rename noienf01-noienf09=noienfc1-noienfc9;
noindiv=compress(ident&acour.!!noicon);run;
proc sort data=corr_ind; by noindiv; run;
proc sort data=enfconj; by noindiv; run;

/*Cr�ation de variables avec les NOI des enfants de la personne ou de son conjoint */
data corr_ind (drop=l);merge corr_ind enfconj;by noindiv;
length listenf $80.;		/*LISTENF : liste des noi des enfants de la personne*/
listenf=compress(noienf01!!noienf02!!noienf03!!noienf04!!noienf05!!noienf06!!noienf07!!noienf08!!noienf09);
%macro noienf_bis;
%do i=1 %to 9;
	if noienfc&i.  ne ' ' then do;
		/*position du NOIENFC dans la liste des enfants de la personne*/
		l=index(listenf,noienfc&i.); 
		/*si on n'a pas trouv� l'enfant du conjoint dans les enfants de la personne, on le rajoute � la liste*/
		if l=0 then listenf=compress(listenf!!noienfc&i.);
	end;
%end;
%do i=1 %to 9;
	length noienft&i. $2.;	/*NOIENFTi : numero du ieme enfant de la personne ou du couple*/
	NOIENFT&i.=substr(listenf,%eval(&i.*2-1),2);
%end;
%mend;
%noienf_bis;
run;
proc datasets library=work;delete enfconj ;run;quit;

			/*** Remplissage du NOIPER quand personne de sexe masculin ayant des beaux-enfants dans le m�nage ***/

		/** NOIBOPER : table avec une ligne par p�re ou beau p�re **/
/*S�lection des personnes de sexe masculin ayant des enfants (y compris beaux enfants) dans le m�nage*/
data noiboper (keep = noienft1-noienft9 noiper2 ident&acour.);set corr_ind;
if sexe='1' & (noienft1 ne ' ' ! noienft2 ne ' ' ! noienft3 ne ' ' ! noienft4 ne ' ' ! noienft5 ne ' ' ! noienft6 ne ' ' ! 
noienft7 ne ' ' ! noienft8 ne ' ' ! noienft9 ne ' '); 
rename noi=noiper2;run;	/*on renomme leur noi comme noi de pere*/
proc sort data=noiboper;by ident&acour. noiper2; run;
proc transpose data=noiboper out=noiboper2 (drop=_NAME_ rename=(col1=noi)); by ident&acour. noiper2; var noienft1-noienft9; run;
data noiboper2;set noiboper2;if noi=' ' then delete;run;
proc sort data=corr_ind ; by ident&acour. noi; run;
proc sort data=noiboper2 nodupkey; by ident&acour. noi; run; 
data corr_ind(drop= noiper2);merge corr_ind  noiboper2 ;by ident&acour. noi;if noiper=' ' & noiper2 ne ' ' then noiper=noiper2; /*??*/
else if (noiper ne ' ') & (noiper2 ne ' ') & (noiper ne noiper2) then noimer=noiper2;run;
proc datasets library=work;delete noiboper noiboper2;run;quit;

			/*** Remplissage du NOIMER quand personne de sexe f�minin ayant des beaux-enfants dans le m�nage ***/

		/** NOIBOMER : table avec une ligne par m�re ou belle m�re **/
/*S�lection des personnes de sexe f�minin ayant des enfants (y compris beaux enfants) dans le m�nage*/
data noibomer (keep = noienft1-noienft9 noimer2 ident&acour.);set corr_ind;
if sexe='2' & (noienft1 ne ' ' ! noienft2 ne ' ' ! noienft3 ne ' ' ! noienft4 ne ' ' ! noienft5 ne ' ' ! noienft6 ne ' ' ! 
noienft7 ne ' ' ! noienft8 ne ' ' ! noienft9 ne ' '); 
rename noi=noimer2;run;	/*on renomme leur noi comme noi de m�re*/
proc sort data=noibomer;by ident&acour. noimer2; run;
proc transpose data=noibomer out=noibomer2 (drop=_NAME_ rename=(col1=noi)); by ident&acour. noimer2; var noienft1-noienft9; run;
data noibomer2;set noibomer2;if noi=' ' then delete;run;
proc sort data=corr_ind; by ident&acour. noi; run;
proc sort data=noibomer2 nodupkey; by ident&acour. noi; run;
data corr_ind (drop = noimer2);merge corr_ind noibomer2 ;by ident&acour. noi;if noimer=' ' & noimer2 ne ' ' then noimer=noimer2; /*?? obs*/
else if (noimer ne ' ') & (noimer2 ne ' ') & (noimer ne noimer2) then noiper=noimer2;run;
proc datasets library=work;delete noibomer noibomer2 ;run;quit;
data corr_ind;set corr_ind;drop noienf01-noienf09 noienfc1-noienfc9 listenf;run;


/**************************************************************************************************************************************************************/
/*		c. Correction de coh�rence entre �tre en couple et avoir le m�me p�re ou la m�me m�re				 							                      */
/**************************************************************************************************************************************************************/

/*On fait confiance au NOIPER/NOIMER et on enl�ve les couples qui ont un parent commun*/
proc sort data=corr_ind; by ident&acour. noi; run;
proc transpose data=corr_ind out=temp1 (drop=_NAME_ _LABEL_) PREFIX=noi;by ident&acour.;var noi ;run;
proc transpose data=corr_ind out=temp2(drop=_NAME_ _LABEL_) PREFIX=noicon;by ident&acour.;var noicon ;run;
proc transpose data=corr_ind out=temp3 (drop=_NAME_ _LABEL_) PREFIX=noiper;by ident&acour.;var noiper ;run;
proc transpose data=corr_ind out=temp4 (drop=_NAME_ _LABEL_) PREFIX=noimer ;by ident&acour.;var noimer ;run;
data conjparent; merge temp1 temp2 temp3 temp4;
by ident13;
%macro correction;
%do i=1 %to 11; 
	%do j=1 %to 11;
if (noicon&i. ne ' ' & noicon&i.=noi&j.) & ((noiper&i. ne ' ' & noiper&i.=noiper&j.)!(noimer&i. ne ' ' & noimer&i.=noimer&j.)) then do; 
noicon&i.=' ';  end;
	%end;
%end;
%mend; %correction;
run;
data corr_ind (drop=noicon1-noicon11 noiper1-noiper11 noimer1-noimer11 noi1-noi11); merge corr_ind conjparent; by ident13; %macro assignation; 
%do i=1 %to 11; if noi=noi&i. then NOICON=noicon&i.; %end;  %mend; %assignation; run;

proc datasets library=work; delete temp1-temp4; run;


/**************************************************************************************************************************************************************/
/*				4- Recherche d'informations compl�mentaires pour les prestations								  						     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Informations sur les s�parations dans les vagues pass�es de l'EEC et les d�clarations fiscales													  */
/**************************************************************************************************************************************************************/

/*Remarque : on r�cup�re les infos du T4 2012 au T3 2013 : l'API courte est ouverte un an apr�s la s�paration*/
%macro passe(a=,t=);

%if &a.>=13 %then %do;
data conj_&a.t&t. (rename =(noicon=noicon&a.t&t. lprm=lprm&a.t&t. typmen7=typmen&a.t&t. matri=matri&a.t&t.));
set erfs_c.icomprf&acour.e&a.t&t.;
keep ident&acour. noi noicon lprm typmen7 matri ;run;
proc sort data=conj_&a.t&t.; by ident&acour. noi; run;

%end;

%else %do;
data conj_&a.t&t. (rename =(noicon=noicon&a.t&t. lpr=lprm&a.t&t. typmen5=typmen&a.t&t. matri=matri&a.t&t.));
set erfs_c.icomprf&acour.e&a.t&t.;
api_eec&a.t&t.=(index(rc1rev,'2')>0); 
keep ident&acour. noi noicon lpr typmen5 matri api_eec&a.t&t. so  ;run;
proc sort data=conj_&a.t&t.; by ident&acour. noi; run;
%end;

%mend;

%passe(a=&aprec.,t=4);
%passe(a=&acour.,t=1);
%passe(a=&acour.,t=2);
%passe(a=&acour.,t=3);

/*S�lection des personnes au T4 2013*/
data passe_eec;
set corr_ind;
keep ident&acour. noi noicon rgi lprm typmen7 matri ;
run;
proc sort data=passe_eec; by ident&acour. noi; run;

/*Ajout de l'information pass�e*/
data passe_eec;
merge passe_eec (in=a) conj_&aprec.t4 conj_&acour.t1 conj_&acour.t2 conj_&acour.t3;
by  ident&acour. noi; 

if a;
run;

/*Declaration au niveau du foyer*/
data foyer (keep = ident&acour. noi dv_fip iso_fip);set foyer&acour._cor; 
if index(sif,'Y')>0 ! index(sif,'Z')>0 then dv_fip=1;	/*DV_FIP : divorce ou deces d�clar� dans d�claration fiscale*/
if index(sif,'T')>0 then iso_fip=1;						/*ISO_FIP : d�clar� isol� dans d�claration fiscale*/
run;

proc sort data=foyer; by ident&acour. noi descending dv_fip; run; /*pour avoir en 1er ceux qui ont eu DV_FIP dans l'ann�e*/
proc sort data=foyer nodupkey; by ident&acour. noi ; run;
data passe (keep = ident&acour. noi sep_eec api_eec dv_fip iso_fip);merge passe_eec (in=a) foyer;by ident&acour. noi;if a;

/*SEP_EEC : on rep�re le fait d'avoir �t� en couple dans l'EEC*/ 
sep_eec=(noicon&aprec.t4 ne ' ' ! noicon&acour.t1 ne ' ' ! noicon&acour.t2 ne ' ' ! noicon&acour.t3 ne ' ' 
! (lprm&aprec.t4 in('1','2') & typmen&aprec.t4 in('3','4')) ! (lprm&acour.t1 in('1','2') & typmen&acour.t1 in('3','4')) 
! (lprm&acour.t2 in('1','2') & typmen&acour.t2 in('3','4')) ! (lprm&acour.t3 in('1','2') & typmen&acour.t3 in('3','4'))); 

/*API_EEC*/
api_eec=api_eec&aprec.t4=1; 
run;
proc datasets library=work;delete conj_: passe_eec foyer;run;quit;


/**************************************************************************************************************************************************************/
/*		b. Naissances futures																									 		                      */
/**************************************************************************************************************************************************************/

/*On recupere les naissances des mois d'octobre, novembre et d�cembre 2013, 2014 et d�but 2015*/ 

%macro futur(a=,t=,n=);
data naiss_&a.t&t. (rename=(noimerc=noi naia2=naissa&n. naim2=naissm&n.)) ;

set erfs_c.icomprf&acour.e&a.t&t.;

naia2=input(naia,4.);
naim2=input(naim,2.);

if (naim2 in (10,11,12) & naia2=20&acour.) ! naia2 in(20&asuiv.,20&asuiv2.); 

noimerc=compress(noimer);
if length(noimerc)=1 & noimerc ne ' ' then noimerc=compress('0'!!noimer);

keep ident&acour. noimerc naia2 naim2;
run;

proc sort data=naiss_&a.t&t.; by ident&acour. noi descending naissa&n. descending naissm&n.; run; /*pour avoir en 1er la naissance la plus r�cente (nodupkey 
																								    garde 1ere observations)*/
proc sort data=naiss_&a.t&t. nodupkey; by ident&acour. noi ; run; 
%mend;

%futur(a=&asuiv.,t=1,n=1);
%futur(a=&asuiv.,t=2,n=2);
%futur(a=&asuiv.,t=3,n=3);
%futur(a=&asuiv.,t=4,n=4);
%futur(a=&asuiv2.,t=1,n=5);

data naiss_&acour.t4 (rename=(noimer=noi naia=naissa0 naim=naissm0)) ;
set corr_ind;
if (naim in (10,11,12) & naia=20&acour.) ! naia=20&asuiv.;
keep ident&acour. noimer naia naim;
run;
proc sort data=naiss_&acour.t4 nodupkey; by ident&acour. noi descending naissa0 descending naissm0; run; 

data naiss;
merge naiss_&acour.t4 naiss_&asuiv.t1 (in=a1) naiss_&asuiv.t2 (in=a2) naiss_&asuiv.t3 (in=a3) naiss_&asuiv.t4 (in=a4) naiss_&asuiv2.t1 (in=a5);
by ident&acour. noi;
/*S�lection des informations sur les naissances � venir seulement, celles du T4 2013 sont d�j� observ�es*/
if a1 ! a2 ! a3 ! a4 ! a5;

%macro naiss;
%do i=0 %to 4;
	/*Mise � blanc des naissances d�j� constat�es */
	%do j=%eval(&i.+1) %to 5;
		if naissa&j. ne . & naissa&i. ne . then do;
			if -6<((naissa&j.*12+naissm&j.)-(naissa&i.*12+naissm&i.))<6 then do; /*cette ligne donne le nombre de mois qui s�parent deux naissances constat�es. 
																				   Le 12 s'explique par le fait que les diff�rences en ann�es doivent �tre 
																				   converties en mois */
				naissa&j.=.;
				naissm&j.=.;
			end;
		end;
	%end;
%end;
/*Selection des obs avec une future naissance*/
if naissa1 ne . ! naissa2 ne . ! naissa3 ne . ! naissa4 ne . ! naissa5 ne .;

%do i=1 %to 5;
	/*NAISS_FUTUR_A : ann�e de la naissance future*/
	/*NAISS_FUTUR_M : mois de la naissance future*/
	/*On consid�re la 1�re naissance */
	if naissa&i. ne . & naiss_futur_a=. then do;
		naiss_futur_a=naissa&i.;
		naiss_futur_m=naissm&i.;
	end;
%end;

/*NAISS_Futur : indicatrice de naissance apres T4 2013*/
naiss_futur=1;

%mend;
%naiss;
run;

proc datasets library=work;delete naiss_: ;run;quit;


/**************************************************************************************************************************************************************/
/*		c. Information sur l'AAH dans l'EEC																						 		                      */
/**************************************************************************************************************************************************************/

/*On r�cup�re cette information grace � la question RC1REV pos�e en 1ere et derni�re interrogation*/
/*On prend les vagues pass�es et futures de l'EEC*/
%macro aah(a=,t=);
data aah_&a.t&t. ;
set erfs_c.icomprf&acour.e&a.t&t.;
%if &a.<13 %then %do ;  if rc1rev ne '' then rc1revm4 = (index(rc1rev,'4')>0);%end ;	/*changement de variable � partir de l'enqu�te emploi 2013*/

aah_eec&a.t&t.=(rc1revm4=1);
if ((rc1revm4 ne ' ')&(aah_eec&a.t&t.=0)) then pas_aah&a.t&t.=1;
if aah_eec&a.t&t.=1 | pas_aah&a.t&t.=1;
keep ident&acour. noi aah_eec&a.t&t. pas_aah&a.t&t.;
run;
proc sort data=aah_&a.t&t.; by ident&acour. noi; run;
%mend;

%aah(a=&aprec.,t=3);
%aah(a=&aprec.,t=4);
%aah(a=&acour.,t=1);
%aah(a=&acour.,t=2);
%aah(a=&acour.,t=3);
%aah(a=&asuiv.,t=1);
%aah(a=&asuiv.,t=2);
%aah(a=&asuiv.,t=3);
%aah(a=&asuiv.,t=4);
%aah(a=&asuiv2.,t=1);

/*Selection des personnes au T4 2013*/
data aah_&acour.t4;set corr_ind;
aah_eec&acour.t4=(rc1revm4=1);
if ((rc1revm4 ne ' ')&(aah_eec&acour.t4=0)) then pas_aah&acour.t4=1;
keep ident&acour. noi aah_eec&acour.t4 pas_aah&acour.t4;
run;
proc sort data=aah_&acour.t4; by ident&acour. noi; run;

/*Ajout de l'information des EEC pr�c�dentes*/
data aah_eec (keep= ident&acour. noi aah_eec);
merge aah_&aprec.t3 aah_&aprec.t4 aah_&acour.t1 aah_&acour.t2 aah_&acour.t3 aah_&acour.t4 (in=a) aah_&asuiv.t1 aah_&asuiv.t2 aah_&asuiv.t3 aah_&asuiv.t4 aah_&asuiv2.t1 ; 
by  ident&acour. noi; 
if a;

/*AAH_EEC*/
aah_eec=(aah_eec&aprec.t3=1 ! aah_eec&aprec.t4=1 ! aah_eec&acour.t1=1 ! aah_eec&acour.t2=1 ! aah_eec&acour.t3=1 ! aah_eec&acour.t4=1 ! aah_eec&asuiv.t1=1 
! aah_eec&asuiv.t2=1 ! aah_eec&asuiv.t3=1 ! aah_eec&asuiv.t4=1 ! aah_eec&asuiv2.t1=1);

/*S'il d�clare ne pas percevoir l'AAH pendant l'ann�e de l'ERFS alors aah_eec=0*/
if ((aah_eec&acour.t1=1 ! aah_eec&acour.t2=1 ! aah_eec&acour.t3=1 ! aah_eec&acour.t4=1)=0) &
	((pas_aah&acour.t1=1 ! pas_aah&acour.t2=1 ! pas_aah&acour.t3=1 ! pas_aah&acour.t4=1)=1) then aah_eec=0;
run;
proc datasets library=work;delete aah_1: ;run;quit;


/**************************************************************************************************************************************************************/
/*		d. Donn�es issues des d�clarations fiscales : d�clarant et conjoint														 		                      */
/**************************************************************************************************************************************************************/

data foyer;
set foyer&acour._cor;
ciconj=(substr(sif,17,1)='F'); /*pension d'invalidit� du conjoint*/ 
ci=(substr(sif,20,1)='P');     /*pension d'invalidit� du d�clarant*/

/*MATRI_FIP : statut matri du d�clarant*/
/*Remarque : quand il y a plusieurs d�clarations, on ne garde que le statut de la 1er*/
length matri_fip $2.;
matri_fip=substr(sif,5,1);		/*statut matrimonial du declarant*/
run;

			/*** MATRI_FIP : statut matrimonial ***/
proc sort data=foyer; by ident&acour. noi;run;
proc sort data=corr_ind; by ident&acour. noi; run;
/*Ajout � la table fiscale le noi du conjoint*/
data info_fisc;
merge corr_ind (keep = noi noicon ident&acour.) foyer (keep = ident&acour. noi sif matri_fip in=a);
by ident&acour. noi; 
if a;
run;

		/** Table d�clarant **/
data info_decl;
set info_fisc;
keep ident&acour. noi matri_fip;
run;

		/** Table conjoint **/
data info_conj (drop=sif);
set info_fisc (keep=ident&acour. sif noicon matri_fip);
/*Selection des d�clarants avec conjoint (les 2 conditions sont importantes, sinon, il y a des valeurs manquantes sur noi)*/
if substr(sif,5,1) in('M','O') & noicon ne ' ';
rename noicon=noi;
run;

/*Mise en commun (set) infos conjoint et d�clarant*/
data matri_fip;
set info_decl info_conj;
run;

/*On supprime les doublons*/
proc sort data=matri_fip nodupkey; by ident&acour. noi; run;
proc datasets library=work;delete info_fisc info_decl info_conj ;run;quit;



			/*** Autres variables ***/
%macro info_fisc(decl=,conj=);
/*Ajout � la table fiscale le noi du conjoint*/
data info_fisc;
merge corr_ind (keep = noi noicon ident&acour.) foyer (keep = ident&acour. noi sif &decl. &conj. in=a);
by ident&acour. noi; 
if a;
run;

		/** Table d�clarant **/
data info_decl;set info_fisc;keep ident&acour. noi &decl.;run;

		/** Table conjoint **/
data info_conj (drop=sif);set info_fisc (keep=ident&acour. sif noicon &conj.);
/*Selection des d�clarants avec conjoint (les 2 conditions sont importantes, sinon, il y a des valeurs manquantes sur noi)*/
if substr(sif,5,1) in('M','O') & noicon ne ' ';
rename noicon=noi;

/*On renomme les variables des conjoints comme celles des d�clarants*/
%let i=1;
%do %while(%index(&conj.,%scan(&conj.,&i.))>0); 

	rename %scan(&conj.,&i.)=%scan(&decl.,&i.);

	%let i=%eval(&i.+1);
%end;

run;

/*Mise en commun (set) des informations sur le conjoint et le d�clarant*/
data info_fip0;set info_decl info_conj;run;
proc sort data=info_fip0; by ident&acour. noi; run;

proc means data=info_fip0 nway noprint; 
by ident&acour. noi; 
var &decl.;
output out=info_fip (drop = _TYPE_ _FREQ_) sum=;
run;

proc datasets library=work;delete info_fisc info_decl info_conj info_fip0 foyer;run;quit;
%mend;

/* _1xK frais r�els */ 
/* _1xI : demandeur d'emploi de plus d'un an*/ 
/*ci : pension d'invalidit�*/
%info_fisc(decl=_1AI _1AK ci,conj=_1BI _1BK ciconj);
data info_fip;set info_fip;_1AI=(_1AI>=1);ci=(ci>=1);run; 


/**************************************************************************************************************************************************************/
/*		e. Individualisation d'information de niveau foyer fiscal																 		                      */
/**************************************************************************************************************************************************************/

data mds_fip (keep = ident&acour. declar mds mariage divorce deces);
set foyer&acour._cor;
/*MDS : mariage, divorce ou deces d�clar� dans la d�claration fiscale*/
MDS=(index(sif,'X')>0 ! index(sif,'Y')>0 ! index(sif,'Z')>0);
mariage=(index(sif,'X')>0);		/*mariage*/
divorce=(index(sif,'Y')>0);		/*divorce*/
deces=(index(sif,'Z')>0);		/*d�c�s*/
run;

data saphir.indivi&acour.; 		/*r�cup�ration de la variable naia*/
merge erfs.indivi&acour.(in=a) corr_ind (keep= ident&acour. noi naia drop=wprm); by ident&acour. noi ;
declar1=compress(declar1);
declar2=compress(declar2);
if a;
run;

/*declar*/
data declar (keep=ident&acour. noi declar1 declar2);set saphir.indivi&acour.;run;

/*declar1*/
data declar1;set declar (keep = ident&acour. noi declar1);if declar1 ne ' ';rename declar1=declar;run;
data mds_fip;set mds_fip;declar=compress(declar);run;
proc sort data=declar1; by ident&acour. declar; run;
proc sort data=mds_fip; by ident&acour. declar; run;

data mds1;length declar $ 79;
merge declar1 (in=a) mds_fip (in=b);by ident&acour. declar; if a & b;
rename mds=mds1 mariage=mariage1 divorce=divorce1 deces=deces1;
run;

/*declar2*/
data declar2;set declar (keep = ident&acour. noi declar2);if declar2 ne ' ';rename declar2=declar;run;
proc sort data=declar2; by ident&acour. declar; run;

data mds2;length declar $ 79;
merge declar2 (in=a) mds_fip (in=b);by ident&acour. declar;if a & b; 
rename mds=mds2 mariage=mariage2 divorce=divorce2 deces=deces2;
run;

/*mds*/
proc sort data=mds1; by ident&acour. noi; run;
proc sort data=mds2; by ident&acour. noi; run;

data mds (keep = ident&acour. noi mds mariage divorce deces);
merge mds1 mds2;
by ident&acour. noi;
mds=(mds1=1 ! mds2=1);
mariage=(mariage1=1 ! mariage2=1);
divorce=(divorce1=1 ! divorce2=1);
deces=(deces1=1 ! deces2=1);
run;

proc datasets library=work;delete mds1 mds2 declar declar1 declar2 mds_fip;run;quit;


/**************************************************************************************************************************************************************/
/*		f. Lien individu/donn�es fiscales																						 		                      */
/**************************************************************************************************************************************************************/

/*DECLARANT : indicatrice qui vaut 1 si individu est d�clarant*/
proc sort data=foyer&acour._cor out=declarant (keep = ident&acour. noi sif) nodupkey; by ident&acour. noi; run;
data declarant;set declarant;declarant=1;run;

/*DECLi et CJDECLi : plus g�n�ral : declarant et conjoint de d�clarant de la declaration i*/
data noi;set corr_ind (keep = noi noicon ident&acour.);run;
data declar;set saphir.indivi&acour. (keep = ident&acour. noi declar1 declar2);run;

proc sort data=noi ; by ident&acour. noi; run;
proc sort data=declar ; by ident&acour. noi; run; 


data decl (keep = ident&acour. noi decl1 decl2 cjdecl1 cjdecl2 persfip2);merge corr_ind declar;by ident&acour. noi; 

/*DECLi : indicatrice : l'individu est d�clarant de la ieme d�claration*/
decl1=(noi=substr(declar1,1,2))*(declar1 ne ' ');
decl2=(noi=substr(declar2,1,2))*(declar2 ne ' ');

/*CJDECLi : indicatrice : l'individu est conjoint de d�clarant de la ieme d�claration*/
cjdecl1=(noicon=substr(declar1,1,2))*(declar1 ne ' ');
cjdecl2=(noicon=substr(declar2,1,2))*(declar2 ne ' ');

/*persfip2*/
if declar2 ne "" then do;
	if decl2=1 then persfip2='vous';
	else if cjdecl2=1 then persfip2='conj';
	else persfip2='pac ';
end;
run;

proc sort data=saphir.indivi&acour.;by ident&acour. noi;run;

data saphir.indivi&acour.;
merge saphir.indivi&acour.(in=a) decl (keep=ident&acour. noi persfip2);
by ident&acour. noi;
if a;
run;

data foyer&acour._cor;
set foyer&acour._cor;
declar=compress(declar);
run;

proc sort data=saphir.indivi&acour.;by declar1; run;
proc sort data=foyer&acour._cor;by declar; run;

data locali_decl1;
length declar1 $ 79;
merge saphir.indivi&acour. (keep=ident&acour. noi declar1 declar2 zsalo zchoo zrsto zragi zrici zrnci naia persfip in=a) 
	foyer&acour._cor(rename=(declar=declar1) drop=noi);
by declar1;
deces=(index(sif,'Z')>0);		/*d�c�s dans l'ann�e*/
fisc_sal="0000";
fisc_cho="0000";
fisc_rst="0000";
fisc_rag="0000";
fisc_ric="0000";
fisc_rnc="0000";

/*Reconstitution des variables de revenus d�clar�s individuels n'apparaissant pas directement dans une case fiscale : BIC, BNC, etc.*/
zsalf_decl=sum(_1aj,_1au,_1aq,_8by); 	/*la case heures suppl�mentaires exon�r�es ne dispara�t pas en 2013 : il reste les HS exon�r�es en 2012 pay�es en 2013*/
zsalf_conj=sum(_1bj,_1bu,_1bq,_8cy);
zsalf_pac1=sum(_1cj,_1cu);
zsalf_pac2=sum(_1dj,_1du);

zragf_decl=sum(_5hn,_5ho,_5hd,_5hb,_5hh,_5hc,_5hi,-_5hf,-_5hl,_5hm, _5hz); 
zragf_conj=sum(_5in,_5io,_5id,_5ib,_5ih,_5ic,_5ii,-_5if,-_5il,_5im, _5iz);
zragf_pac1=sum(_5jn,_5jo,_5jd,_5jb,_5jh,_5jc,_5ji,-_5jf,-_5jl,_5jm, _5jz);

	/** Revenus industriels et commerciaux professionnels (BIC)**/
/*R�gime micro et autoentrepreneur : revenu d�clar� = chiffre d'affaire moins avec abattement sur chiffre d'affaire*/
KOPTABtax=round(max(_5ko+_5kp+_5ta+_5tb-max(&E2000.,_5ko*0.71+_5kp*0.50+_5ta*0.71+_5tb*0.50),0));
LOPUABtax=round(max(_5lo+_5lp+_5ua+_5ub-max(&E2000.,_5lo*0.71+_5lp*0.50+_5ua*0.71+_5ub*0.50),0));
MOPVABtax=round(max(_5mo+_5mp+_5va+_5vb-max(&E2000.,_5mo*0.71+_5mp*0.50+_5va*0.71+_5vb*0.50),0));
/*Ajout du reste des revenus pour inclure les d�clarations BIC/BNC au r�el*/
zricf_decl=sum(_5kn,KOPTABtax,_5kb,_5kh,_5kc,_5ki,_5ha,_5ka,-_5kf,-_5kl,-_5qa,-_5qj,_5ks);
zricf_conj=sum(_5ln,LOPUABtax,_5lb,_5lh,_5lc,_5li,_5ia,_5la,-_5lf,-_5ll,-_5ra,-_5rj,_5ls);
zricf_pac1=sum(_5mn,MOPVABtax,_5mb,_5mh,_5mc,_5mi,_5ja,_5ma,-_5mf,-_5ml,-_5sa,-_5sj,_5ms);

	/** Revenus non commerciaux professionnels (BNC) **/
HQTEtax=round(max(_5hq+_5te-max(&E2000.,_5hq*0.34+_5te*0.34),0));
IQUEtax=round(max(_5iq+_5ue-max(&E2000.,_5iq*0.34+_5ue*0.34),0));
JQVEtax=round(max(_5jq+_5ve-max(&E2000.,_5jq*0.34+_5ve*0.34),0));

zrncf_decl=sum(_5hp,HQTEtax,_5qb,_5qh,_5qc,_5qi,-_5qe,-_5qk,_5ql,_5qm,_5tf,_5ti);
zrncf_conj=sum(_5ip,IQUEtax,_5rb,_5rh,_5rc,_5ri,-_5re,-_5rk,_5rl,_5rm,_5uf,_5ui);
zrncf_pac1=sum(_5jp,JQVEtax,_5sb,_5sh,_5sc,_5si,-_5se,-_5sk,_5sl,_5vf,_5vi);



vousconj=substr(sif,6,4)!!"-"!!substr(sif,11,4);
aged=input(substr(vousconj,1,4),4.0);
agec=input(substr(vousconj,6,4),4.0); 

evenement=0;
if (declar2 ne "")|(deces ne 1) then evenement=1;

		/** D�claration unique **/
if evenement=0 then do;

	/*Salaires*/
	if zsalo>0 then do;
		if (zsalo=zsalf_decl)&(persfip="vous") then fisc_sal="decl";
		else if zsalo=zsalf_conj then fisc_sal="conj";
		else if zsalo=zsalf_pac1 then fisc_sal="pac1";
		else if zsalo=zsalf_pac2 then fisc_sal="pac2";
		else fisc_sal="prob";
	end;

	/*Ch�mage (inclut pr�retraites)*/
	if zchoo>0 then do;
		if (zchoo=_1ap)&(persfip="vous") then fisc_cho="decl";
		else if zchoo=_1bp then fisc_cho="conj";
		else if zchoo=_1cp then fisc_cho="pac1";
		else if zchoo=_1dp then fisc_cho="pac2";
		else fisc_cho="prob";
	end;

	/*Retraite*/
	if zrsto>0 then do;
		if (zrsto=_1as)&(persfip="vous") then fisc_rst="decl";
		else if zrsto=_1bs then fisc_rst="conj";
		else if zrsto=_1cs then fisc_rst="pac1";
		else if zrsto=_1ds then fisc_rst="pac2";
		else fisc_rst="prob";
	end;

	/*Revenus agricoles*/
	if zragi ne 0 then do;	/*on reste en i, pour attribuer les forfaits*/
		if (zragi=zragf_decl)&(persfip="vous") then fisc_rag="decl";
		else if (zragf_decl=0)&(persfip="vous")&(forva=1) then fisc_rag="decl";	
		else if zragi=zragf_conj then fisc_rag="conj";
		else if (zragf_conj=0)&(persfip="conj")&(forca=1) then fisc_rag="conj";	
		else if zragi=zragf_pac1 then fisc_rag="pac1";
		else if (zragf_pac1=0)&(persfip="pac")&(forpa=1) then fisc_rag="pac1";	
		else fisc_rag="prob";
	end;

	/*Revenus industriels et commerciaux*/
	if zrici ne 0 then do;
		if (abs(zrici-zricf_decl)<2)&(persfip="vous") then fisc_ric="decl";
		else if abs(zrici-zricf_conj)<2 then fisc_ric="conj";
		else if abs(zrici-zricf_pac1)<2 then fisc_ric="pac1";
		else fisc_ric="prob";
	end;

	/*Revenus non commerciaux*/
	if zrnci ne 0 then do;
		if (abs(zrnci-zrncf_decl)<2)&(persfip="vous") then fisc_rnc="decl";
		else if abs(zrnci-zrncf_conj)<2 then fisc_rnc="conj";
		else if abs(zrnci-zrncf_pac1)<2 then fisc_rnc="pac1";
		else fisc_rnc="prob";
	end;

end;

		/** Deux d�clarations **/
else do;

	/*Salaires*/
	if zsalo>0 then do;
		if (zsalf_decl>0)&(naia=aged)&(persfip="vous") then fisc_sal="decl";
		else if (zsalf_decl>0)&(naia ne agec)&(naia ne aged)&(persfip="vous") then fisc_sal="decl";	/*probl�me sur la date de naissance*/
		else if (zsalf_decl=0)&(naia=aged)&(persfip="vous") then fisc_sal="0000";					/*pas de salaire dans cette declaration*/
		else if (zsalf_conj>0)&(naia=agec)&(persfip="conj") then fisc_sal="conj";
		else if (zsalf_conj>0)&(naia ne agec)&(naia ne aged)&(persfip="conj") then fisc_sal="conj";	/*probl�me de date de naissance*/
		else if (zsalf_conj=0)&(naia=agec)&(persfip="conj") then fisc_sal="0000";					/*pas de salaire dans cette declaration*/
		else if (zsalf_pac1>0)&(persfip="pac")&(zsalf_pac2=0) then fisc_sal="pac1";
		else fisc_sal="prob";
	end;

	/*Chomage*/
	if zchoo>0 then do;
		if (_1ap>0)&(naia=aged)&(persfip="vous") then fisc_cho="decl";
		else if (max(_1ap,_1bp,_1cp,_1dp)=0)&(naia=aged)&(persfip="vous") then fisc_cho="0000";				/*pas de ch�mage dans cette d�claration-l�*/
		else if (max(_1ap,_1cp,_1dp)=0)&(naia=aged)&(naia ne agec)&(persfip="vous") then fisc_cho="0000";	/*pas de ch�mage dans cette d�claration-l�, m�me 
																											  si conjoint en a*/
		else if (_1bp>0)&(naia=agec)&(persfip="conj") then fisc_cho="conj";
		else if (max(_1ap,_1bp,_1cp,_1dp)=0)&(naia=agec)&(persfip="conj") then fisc_cho="0000";				/*pas de ch�mage dans cette d�claration-l�*/
		else if (max(_1bp,_1cp,_1dp)=0)&(naia=agec)&(naia ne aged)&(persfip="conj") then fisc_cho="0000";	/*pas de ch�mage dans cette d�claration-l�, m�me 
																											  si d�clarant en a*/
		else if (_1cp>0)&(_1dp=0)&(persfip="pac") then fisc_cho="pac1";
		else fisc_cho="prob";
	end;

	/*Retraite*/
	if zrsto>0 then do;
		if (_1as>0)&(naia=aged)&(persfip="vous") then fisc_rst="decl";
		else if (_1as>0)&(max(_1bs,_1cs,_1ds)=0)&(persfip="vous") then fisc_rst="decl";			/*probl�me sur la date de naissance*/
		else if (_1as>0)&(naia ne agec)&(naia ne aged)&(persfip="vous") then fisc_rst="decl";	/*probl�me sur la date de naissance*/
		else if (max(_1as,_1bs,_1cs,_1ds)=0)&(naia=aged)&(persfip="vous") then fisc_rst="0000";	/*pas de retraite dans cette d�claration-l�*/
		else if (_1as=0)&(naia=aged)&(naia ne agec)&(persfip="vous") then fisc_rst="0000";		/*pas de retraite dans cette d�claration-l�*/
		else if (_1bs>0)&(naia=agec)&(persfip="conj") then fisc_rst="conj";
		else if (_1bs=0)&(naia=agec)&(persfip="conj") then fisc_rst="0000";						/*pas de retraite dans cette d�claration-l�*/
		else if (_1cs>0)&(persfip="pac")&(_1ds=0) then fisc_rst="pac1";
		else if (_1ds>0)&(persfip="pac")&(_1cs=0) then fisc_rst="pac2";
		else fisc_rst="prob";
	end;

	/*Revenus agricoles*/
	if zragi ne 0 then do;
		if (zragf_decl ne 0)&(naia=aged)&(persfip="vous") then fisc_rag="decl";
		else if (zragf_decl=0)&(persfip="vous")&(naia=aged)&(forva=1) then fisc_rag="conj";	/*forfait agricole � fixer*/
		else if (zragf_decl=0)&(naia=aged)&(persfip="vous") then fisc_rag="0000";			/*pas de revenus agricoles dans cette declaration*/
		else if (zragf_conj ne 0)&(naia=agec)&(persfip="conj") then fisc_rag="conj";
		else if (zragf_conj=0)&(persfip="conj")&(naia=agec)&(forca=1) then fisc_rag="conj";	/*forfait agricole � fixer*/
		else fisc_rag="prob";
	end;

	/*Revenus industriels et commerciaux*/
	if zrici ne 0 then do;
		if (zricf_decl ne 0)&(naia=aged)&(persfip="vous") then fisc_ric="decl";
		else if (max(zricf_decl,zricf_conj,zricf_pac1)=0)&(naia=aged)&(persfip="vous") then fisc_ric="0000";	/*pas de BIC dans cette declaration*/
		else if (zricf_conj ne 0)&(naia=agec)&(persfip="conj") then fisc_ric="conj";
		else if (max(zricf_decl,zricf_conj,zricf_pac1)=0)&(naia=agec)&(persfip="conj") then fisc_ric="0000";	/*pas de BIC dans cette declaration*/
		else fisc_ric="prob";
	end;

	/*Revenus non commerciaux*/
	if zrnci ne 0 then do;
		if (zrncf_decl ne 0)&(naia=aged)&(persfip="vous") then fisc_rnc="decl";
		else if (max(zrncf_decl,zrncf_conj,zrncf_pac1)=0)&(naia=aged)&(persfip="vous") then fisc_rnc="0000";	/*pas de BNC dans cette declaration*/
		else if (zrncf_conj ne 0)&(naia=agec)&(persfip="conj") then fisc_rnc="conj";
		else if (zrncf_conj=0)&(naia=agec)&(persfip="conj") then fisc_rnc="0000";								/*pas de BNC dans cette declaration*/
		else if (zrncf_conj=0)&(naia ne agec)&(naia ne aged)&(persfip="conj") then fisc_rnc="0000";				/*pas de BNC dans cette declaration et 
																												  probl�me de date de naissance*/
		else fisc_rnc="prob";
	end;

end;

/*Identification du reliquat d'heures sup exon�r�es en 2012 pay�es en 2013*/
if fisc_sal="decl" then hs1=_1au;
else if fisc_sal="conj" then hs1=_1bu;
else if fisc_sal="pac1" then hs1=_1cu;
else if fisc_sal="pac2" then hs1=_1du;

/*Salaires �trangers*/
if persfip="vous" then salaire_etr1=_1lz;
else if persfip="conj" then salaire_etr1=_1mz;

if a & (declar1 ne "");
run;

proc sort data=saphir.indivi&acour.;by declar2; run;

data locali_decl2;
length declar2 $ 79;
merge saphir.indivi&acour. (keep=ident&acour. noi declar1 declar2 zsali zchoi zrsti zragi zrici zrnci naia persfip2 in=a) 
	foyer&acour._cor(rename=(declar=declar2)  drop=noi);
by declar2;

fisc_sal2="0000";
fisc_cho2="0000";
fisc_rst2="0000";
fisc_rag2="0000";
fisc_ric2="0000";
fisc_rnc2="0000";

zsalf_decl=sum(_1aj,_1au,_1aq,_8by);
zsalf_conj=sum(_1bj,_1bu,_1bq,_8cy);
zsalf_pac1=sum(_1cj,_1cu);
zsalf_pac2=sum(_1dj,_1du);

zragf_decl=sum(_5hn,_5ho,_5hd,_5hb,_5hh,_5hc,_5hi,-_5hf,-_5hl,_5hm);
zragf_conj=sum(_5in,_5io,_5id,_5ib,_5ih,_5ic,_5ii,-_5if,-_5il,_5im);
zragf_pac1=sum(_5jn,_5jo,_5jd,_5jb,_5jh,_5jc,_5ji,-_5jf,-_5jl,_5jm);

KOPTABtax=round(max(_5ko+_5kp+_5ta+_5tb-max(&E2000.,_5ko*0.71+_5kp*0.50+_5ta*0.71+_5tb*0.50),0));	/*abattement r�gime micro et autoentrepreneur*/
LOPUABtax=round(max(_5lo+_5lp+_5ua+_5ub-max(&E2000.,_5lo*0.71+_5lp*0.50+_5ua*0.71+_5ub*0.50),0));	/*abattement r�gime micro et autoentrepreneur*/
MOPVABtax=round(max(_5mo+_5mp+_5va+_5vb-max(&E2000.,_5mo*0.71+_5mp*0.50+_5va*0.71+_5vb*0.50),0));	/*abattement r�gime micro et autoentrepreneur*/
zricf_decl=sum(_5kn,KOPTABtax,_5kb,_5kh,_5kc,_5ki,_5ha,_5ka,-_5kf,-_5kl,-_5qa,-_5qj,_5ks);
zricf_conj=sum(_5ln,LOPUABtax,_5lb,_5lh,_5lc,_5li,_5ia,_5la,-_5lf,-_5ll,-_5ra,-_5rj,_5ls);
zricf_pac1=sum(_5mn,MOPVABtax,_5mb,_5mh,_5mc,_5mi,_5ja,_5ma,-_5mf,-_5ml,-_5sa,-_5sj,_5ms);

HQTEtax=round(max(_5hq+_5te-max(&E2000.,_5hq*0.34+_5te*0.34),0));		/*abattement r�gime micro et autoentrepreneur*/
IQUEtax=round(max(_5iq+_5ue-max(&E2000.,_5iq*0.34+_5ue*0.34),0));		/*abattement r�gime micro et autoentrepreneur*/
JQVEtax=round(max(_5jq+_5ve-max(&E2000.,_5jq*0.34+_5ve*0.34),0));		/*abattement r�gime micro et autoentrepreneur*/
zrncf_decl=sum(_5hp,HQTEtax,_5qb,_5qh,_5qc,_5qi,-_5qe,-_5qk,_5ql,_5qm,_5tf,_5ti);
zrncf_conj=sum(_5ip,IQUEtax,_5rb,_5rh,_5rc,_5ri,-_5re,-_5rk,_5rl,_5rm,_5uf,_5ui);
zrncf_pac1=sum(_5jp,JQVEtax,_5sb,_5sh,_5sc,_5si,-_5se,-_5sk,_5sl,_5vf,_5vi);

vousconj=substr(sif,6,4)!!"-"!!substr(sif,11,4);
aged=input(substr(vousconj,1,4),4.0);
agec=input(substr(vousconj,6,4),4.0); 

if zsali>0 then do;
	if (zsalf_decl>0)&(naia=aged)&(persfip2="vous") then fisc_sal2="decl";
	else if (zsalf_decl>0)&(max(zsalf_conj,zsalf_pac1,zsalf_pac2)=0)&(persfip2="vous") then fisc_sal2="decl";	/*probl�me sur la date de naissance*/
	else if (zsalf_decl>0)&(naia ne aged)&(naia ne agec)&(persfip2="vous") then fisc_sal2="decl";				/*probl�me sur la date de naissance*/
	else if (zsalf_decl=0)&(naia=aged)&(persfip2="vous") then fisc_sal2="0000";									/*pas de salaire dans cette declaration*/
	else if (max(zsalf_decl,zsalf_conj,zsalf_pac1,zsalf_pac2)=0)&(persfip2="vous") then fisc_sal2="0000";		/*pas de salaire dans cette d�claration*/
	else if (zsalf_conj>0)&(naia=agec)&(persfip2="conj") then fisc_sal2="conj";
	else if (zsalf_pac1>0)&(persfip2="pac")&(zsalf_pac2=0) then fisc_sal2="pac1";
	else if (max(zsalf_pac1,zsalf_pac2)=0)&(persfip2="pac") then fisc_sal2="0000";								/*pas de salaire dans cette declaration*/
	else fisc_sal2="prob";
end;

/*Chomage*/
if zchoi>0 then do;
	if (_1ap>0)&(naia=aged)&(persfip2="vous") then fisc_cho2="decl";
	else if (_1ap>0)&(max(_1bp,_1cp,_1dp)=0)&(naia ne aged)&(naia ne agec)&(persfip2="vous") then fisc_cho2="decl";	/*probl�me sur la date de naissance*/
	else if (_1ap=0)&(naia=aged)&(naia ne agec)&(persfip2="vous") then fisc_cho2="0000";							/*pas de ch�mage dans cette d�claration-l�*/
	else if (max(_1ap,_1bp,_1cp,_1dp)=0)&(naia=aged)&(persfip2="vous") then fisc_cho2="0000";						/*pas de ch�mage dans cette d�claration-l�*/
	else if (_1bp>0)&(naia=agec)&(persfip2="conj") then fisc_cho2="conj";
	else if (max(_1ap,_1bp,_1cp,_1dp)=0)&(persfip2="pac") then fisc_cho2="0000";									/*pas de ch�mage dans cette d�claration-l�*/
	else fisc_cho2="prob";
end;

/*Retraite*/
if zrsti>0 then do;
	if (_1as>0)&(naia=aged)&(persfip2="vous") then fisc_rst2="decl";
	else if (max(_1as,_1bs,_1cs,_1ds)=0)&(naia=aged)&(persfip2="vous") then fisc_rst2="0000";	/*pas de retraite dans cette d�claration-l�*/
	else if (_1as=0)&(naia=aged)&(naia ne agec)&(persfip2="vous") then fisc_rst2="0000";		/*pas de retraite dans cette d�claration-l�*/
	else if (_1bs>0)&(naia=agec)&(persfip2="conj") then fisc_rst2="conj";
	else if (_1cs>0)&(persfip2="pac")&(_1ds=0) then fisc_rst2="pac1";
	else if (max(_1as,_1bs,_1cs,_1ds)=0)&(persfip2="pac") then fisc_rst2="0000";				/*pas de retraite dans cette d�claration-l�*/
	else fisc_rst2="prob";
end;

/*Revenus agricoles*/
if zragi ne 0 then do;
	if (zragf_decl ne 0)&(naia=aged)&(persfip2="vous") then fisc_rag2="decl";
	else if (max(zragf_decl,zragf_conj,zragf_pac1)=0)&(naia=aged)&(persfip2="vous") then fisc_rag2="0000";	/*pas de revenus agricoles dans cette declaration*/
	else if (zragf_conj ne 0)&(naia=agec)&(persfip2="conj") then fisc_rag2="conj";
	else fisc_rag2="prob";
end;

/*Revenus industriels et commerciaux*/
if zrici ne 0 then do;
	if (zricf_decl ne 0)&(naia=aged)&(persfip2="vous") then fisc_ric2="decl";
	else if (max(zricf_decl,zricf_conj,zricf_pac1)=0)&(persfip2="vous") then fisc_ric2="0000";	/*pas de BIC dans cette declaration*/
	else if (zricf_conj ne 0)&(naia=agec)&(persfip2="conj") then fisc_ric2="conj";
	else fisc_ric2="prob";
end;

/*Revenus non commerciaux*/
if zrnci ne 0 then do;
	if (zrncf_decl ne 0)&(naia=aged)&(persfip2="vous") then fisc_rnc2="decl";
	else if (max(zrncf_decl,zrncf_conj,zrncf_pac1)=0)&(naia=aged)&(persfip2="vous") then fisc_rnc2="0000";	/*pas de BNC dans cette declaration*/
	else if (zrncf_decl ne 0)&(max(zrncf_conj,zrncf_pac1)=0)&(naia ne aged)&(naia ne agec)&(persfip2="vous") then fisc_rnc2="decl";/*pas de BNC  dans cette 
																																	 declaration*/
	else if (zrncf_conj ne 0)&(naia=agec)&(persfip2="conj") then fisc_rnc2="conj";
	else fisc_rnc2="prob";
end;

/*Identification des heures suppl�mentaires*/
if fisc_sal2="decl" then hs2=_1au;
else if fisc_sal2="conj" then hs2=_1bu;
else if fisc_sal2="pac1" then hs2=_1cu;
else if fisc_sal2="pac2" then hs2=_1du;

/*Salaires �trangers*/
if persfip2="decl" then salaire_etr2=_1lz;
else if persfip2="conj" then salaire_etr2=_1mz;

if a & (declar2 ne "");
run;

proc sort data=locali_decl1;by ident&acour. noi; run;
proc sort data=locali_decl2;by ident&acour. noi; run;

data donnees_fiscales;
merge locali_decl1(keep=ident&acour. noi fisc_: hs1 salaire_etr1) locali_decl2(keep=ident&acour. noi fisc_: hs2 salaire_etr2);
by ident&acour. noi;
hs=max(0,sum(hs1,hs2));
salaire_etr=max(0,sum(salaire_etr1,salaire_etr2));
drop hs1 hs2 salaire_etr1 salaire_etr2;
run;

proc sort data=saphir.indivi&acour.;by ident&acour. noi; run;

/*Rajout des heures suppl�mentaires individualis�es et des liens avec les cases fiscales � indivi13*/
data saphir.indivi&acour.;merge saphir.indivi&acour. donnees_fiscales;by ident&acour. noi;run;

proc datasets library=work;delete noi declar locali_decl1 locali_decl2 donnees_fiscales;run;quit;


/*************************************************************************************************************************************************************/
/*		g. R�affectation de variables de niveau m�nage																			 		                     */
/*************************************************************************************************************************************************************/

/*Les personnes de moins de 15 ans sont manquantes*/
proc sort data=corr_ind; by ident&acour. lprm; run;

data info_men;
set corr_ind (keep = ident&acour. acteu6prmcj acteu6prm);
by ident&acour.;
if first.ident&acour. then output;
run;


/*************************************************************************************************************************************************************/
/*		h. Ajout � CORR_IND																										 		                     */
/*************************************************************************************************************************************************************/

proc sort data=corr_ind; by ident&acour. noi; run;

data ind_enr;
merge corr_ind (in=a) naiss passe aah_eec info_fip declarant decl mds matri_fip;
by ident&acour. noi;
if a;
/*On met CI � 0 pour ceux qui ne sont ni d�clarants ni conjoints*/
if ci=. then ci=0;
if mds=. then mds=0;
if mariage=. then mariage=0;
if divorce=. then divorce=0;
if deces=. then deces=0;
run;

/*Information au niveau du m�nage*/
data ind_enr;
merge ind_enr (in=a) info_men;
by ident&acour. ;
if a;
run;

proc datasets library=work;delete naiss passe aah_eec info_fip declarant mds matri_fip info_men decl;run;quit;


/*************************************************************************************************************************************************************/
/*		i. Reconstruction ELIG_AAH : eligibilit� � l'AAH																		 		                     */
/*************************************************************************************************************************************************************/

			/*** Information de l'ERFS ***/

/*On se base sur le montant d'AAH r�colt� dans ERFS pour approcher le nombre de b�n�ficiaire d'AAH dans le m�nage*/
proc sort data=erfs.menage&acour. out=aah_erfs (keep = ident&acour. m_aahm m_minvm); by ident&acour.; run;

data aah_erfs ;
set aah_erfs ; 

/*NB_AAH_ERFS : nombre d'AAH dans le m�nage*/
nb_aah_erfs=0;
/*Montant annuel moyen 2013 prenant en compte la revalorisation de septembre : c'est aussi le mode de la distribution*/
if 0<m_aahm<=9373 then nb_aah_erfs=1;   
else if m_aahm>9373 then nb_aah_erfs=2;

/*NB_minvi : nombre de minimum vieillesse dans le m�nage*/
nb_minvi=0;
if 0<m_minvm<=9417 then nb_minvi=1;    /*V�rifier le mode de la distribution : pour 2013, il s'agit de 9417, soit le montant moyen incluant la revalorisation d'avril*/
else if m_minvm>9417 then nb_minvi=2;
run;

			/*** Information de Saphir ***/

/*SAPHIR : table individuelle*/
proc sort data=ind_enr out =saphir 
(keep = ident&acour. agenq noi lprm nondic RAISNSOU RAISPAS RAISTP RAISTF RAISON rabs ci aah_eec actop /*acesse acessep*/ circ dimtyp empabs); 
by ident&acour. noi; 
run; 

/*SAPH_MEN : table une ligne par m�nage */
data saph_men (keep = ident&acour. nb_aah_eec);
set saphir;
by ident&acour.;
retain nb_aah_eec 0;

/*NB_AAH_EEC : nombre de b�n�ficiaires de l'AAH d�clar�s dans l'EEC*/
if first.ident&acour. then nb_aah_eec=0;
if aah_eec=1 then nb_aah_eec=nb_aah_eec+1;
if last.ident&acour. then output;
run;

			/*** Mise en commun ***/

/*ELIG_AAH : table individuelle */
data elig_aah (drop = raisnsou raispas raistf raison nondic circ dimtyp empabs rabs);
merge aah_erfs (in=a) saphir saph_men;
by ident&acour.;
if a;
if nb_aah_erfs=. then nb_aah_erfs=0;

/*TRAV_INV : invalidit� avanc�e pour motif dans parcours professionnel*/
trav_inv=(nondic='5' ! circ='3');

/*TRAV_MALAD : maladie avanc�e pour motif dans parcours professionnel*/
trav_malad=(raistf='1' ! RAISNSOU='3' ! raison='4' ! dimtyp='2' ! empabs='1'  ! rabs='2' );

run;

/*On trie pour avoir dans chaque m�nage en 1er celui qui d�clare dans EEC avoir AAH, puis CI (indicatrice de pension d'invalidit� dans la d�claration), etc... */ 
proc sort data=elig_aah ; by ident&acour. descending aah_eec descending ci descending trav_inv descending trav_malad descending actop lprm; run;

data elig_aah (keep = ident&acour. noi elig_aah nb_minvi agenq elig_minvi);
set elig_aah;
by ident&acour. ;
/*NB_AAH_SAPHIR : nombre d'�ligibles � l'AAH estim� dans Saphir, apr�s recoupement des informations fiscales et de l'EEC*/
retain nb_aah_saphir 0;

/*ELIG_AAH : indicatrice d'�ligibilit� � l'AAH*/
/*Si la personne se d�clare b�n�ficiaire dans l'EEC, elle est consid�r�e comme �ligible*/
elig_aah=aah_eec;

/*On initialise NB_AAH_SAPHIR par NB_AAH_EEC*/
if first.ident&acour. then nb_aah_saphir=nb_aah_eec;

/*Si le nombre d'�ligibles estim� avec l'ERFS est inf�rieur, on cherche l'�ligible le plus probable (cf. tri pr�alable)*/
if nb_aah_saphir<nb_aah_erfs & agenq>=20 then do;
	nb_aah_saphir=nb_aah_saphir+1;
	elig_aah=1;
end;

elig_minvi=(agenq>=60 & elig_aah=1) | agenq>=65;
run;

proc sort data=elig_aah; by ident&acour. descending elig_minvi descending agenq; run;

/*On alloue les minimum vieillesse aux plus de 65 ans, sinon c'est elig_aah entre 62 et 65 ans*/
data elig_aah (keep = ident&acour. noi elig_aah);
set elig_aah;
by ident&acour.;
retain minvi_a_allouer 0;
if first.ident&acour. then minvi_a_allouer=nb_minvi;

/*Si la personne a plus de 65 ans, ok pour le minvi, pas d'information sur le handicap*/
if (agenq>=65)&(minvi_a_allouer>0) then minvi_a_allouer=minvi_a_allouer-1;
/*Si la personne a entre 62 et 65 ans, c'est qu'il a un handicap : la personne touchera le minimum vieillesse dans le  programme 12*/
else if (agenq>=62)&(minvi_a_allouer>0) then do;
	minvi_a_allouer=minvi_a_allouer-1;
	elig_aah=1;
end;

run;

proc sort data=elig_aah; by ident&acour. noi; run;
proc datasets library=work;delete aah_erfs saphir saph_men;run;quit;


/*************************************************************************************************************************************************************/
/*		j. Reconstruction de la variable pr�retraite � partir des tables compl�mentaire											 		                     */
/*************************************************************************************************************************************************************/

/* NB : � partir de l'EEC 2013 la variable pr�retraite n'est plus demand�e qu'en vague 1 et 6 aux personnes entre 53 et 65 ans. On fait une g�n�ralisation en 
disant que quiconque est � un moment en pr�retraite le demeure.*/

%macro recup_preret(a=,t=);
%if &a.<13 %then %do;

data preret_&a.t&t._i;
set erfs_c.icomprf&acour.e&a.t&t.;
keep ident&acour. noi retrai ret&a.t&t. preret&a.t&t.;
if retrai = '1' then ret&a.t&t.='1';
if retrai= '2' then preret&a.t&t.='1';
run;
%end;

%else %do;
data preret_&a.t&t._i (rename = (preret=preret&a._t&t.));
set erfs_c.icomprf&acour.e&a.t&t.;
keep ident&acour. noi preret ;run;
%end;

proc sort data=preret_&a.t&t._i; by ident&acour. noi; run;
%mend;

%recup_preret(a=&aprec.,t=3);
%recup_preret(a=&aprec.,t=4);
%recup_preret(a=&acour.,t=1);
%recup_preret(a=&acour.,t=2);
%recup_preret(a=&acour.,t=3);
%recup_preret(a=&asuiv.,t=1);
%recup_preret(a=&asuiv.,t=2);
%recup_preret(a=&asuiv.,t=3);
%recup_preret(a=&asuiv.,t=4);
%recup_preret(a=&asuiv2.,t=1);


data ind_enr; 
merge ind_enr(in=a) preret_12t3_i preret_12t4_i preret_13t1_i preret_13t2_i preret_13t3_i  preret_14t1_i  preret_14t2_i preret_14t3_i  preret_14t4_i
 preret_15t1_i;
by ident&acour. noi;
if a;
if preret = '1' ! preret13_t1 = '1' ! preret13_t2 = '1' ! preret13_t3 = '1' ! preret14_t1 = '1' ! preret14_t2 = '1'! preret14_t3= '1' ! preret14_t4 = '1'! preret15_t1 = '1'
then do; preret='1'; end;
run;

data ind_enr; set ind_enr; drop preret12: preret13:; run;
proc datasets library=work ; delete so_12: so_13:; run; 



/*************************************************************************************************************************************************************/
/*				5- Cr�ation d'une table en dur															  								     				 */
/*************************************************************************************************************************************************************/

data saphir.irf&acour.e&acour.t4c (compress = yes);merge ind_enr elig_aah;by ident&acour. noi;

/*ENCEINTEP3 : enceinte de plus de 3 mois au moment de l'enqu�te*/
if sexe='2' then do;
	enceintep3=0;
	if naiss_futur_a ne . & 0<(naiss_futur_a*12+naiss_futur_m)-(colla*12+collm)<=6 then enceintep3=1;
end;

/*FORTER*/
if forter=' ' then do;
	if agenq<=16 then forter='2';
	else forter='9';
end;
run;

proc datasets library=work;delete ind_enr elig_aah corr_ind;run;quit;




/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*                       											III. Table m�nage			                 										     */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

proc sort data=saphir.irf&acour.e&acour.t4c; by ident&acour.; run; 

data comp_men (keep = ident&acour. nbi14m nbi14p nb_uc colla collm collj);
set saphir.irf&acour.e&acour.t4c ;
by ident&acour.;

retain  nbi14m 0 nbi14p 0 ;
if first.ident&acour. then do;
	nbi14m=0;       /*moins de 14 ans*/
	nbi14p=0;       /*plus de 14 ans*/
end;
if agenq<14 then nbi14m=nbi14m+1;
if agenq>=14 then nbi14p=nbi14p+1;

nb_uc=1+0.5*(nbi14p-1)+0.3*nbi14m; 	/*NB_UC : nombre d'UC dans le m�nage � la date d'enqu�te*/ 

if last.ident&acour. then output;
run;

proc sort data=erfs.mrf&acour.e&acour.t4 out=mrf&acour.e&acour.t4; by ident&acour.; run; 
data saphir.mrf&acour.e&acour.t4c (compress = yes); merge mrf&acour.e&acour.t4 comp_men (in=b);by ident&acour.; if b;run; 	/*champ ERFS*/


data saphir.irf&acour.e&acour.t4c;  merge saphir.irf&acour.e&acour.t4c (in=a) erfs_c.varsup_2013 (in = b keep=ident&acour. noi logt); by ident&acour. noi; if a; run;

proc sql; create table logt_men as select ident&acour., max(logt) as logt from saphir.irf&acour.e&acour.t4c (keep=ident&acour. logt) group by ident&acour. order by ident&acour.; quit;
data saphir.mrf&acour.e&acour.t4c; merge saphir.mrf&acour.e&acour.t4c (in=a) logt_men; by ident&acour.; if a; run;
proc datasets library=work;delete comp_men mrf&acour.e&acour.t4;run;quit;


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/
