

/**************************************************************************************************************************************************************/
/*                                   									SAPHIR E2013 L2017                                       					   		  */
/*                                      								   PROGRAMME 14                                         					   		  */
/*                   									Calcul du non recours dans Saphir - Prime d'activit�                     					   		  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* La simulation du non-recours vise � obtenir pour chaque configuration familiale de foyer prime d'activit� un nombre de b�n�ficiaires proche de celui 	  */
/* observ� par les Caf. Ces cibles correspondent au nombre de foyers prime d'activit� observ�s. Chaque foyer prime d'activit� se voit attribuer un nombre     */
/* al�atoire entre 0 et 1, repr�sentant sa propension de non-recours sur l'ensemble de l'ann�e et d�pendant du montant de prime auquel il a droit. On d�finit */
/* des sous-populations selon le cumul avec le RSA socle, l'�ge (jeunes) et la configuration familiale. Le nombre de foyers recourant � chaque trismestre est */
/* cal� pour chaque sous-population. La probabilit� de recours est d'autant plus forte que les droits sont �lev�s, et que le m�nage a recourru � la prime le  */
/* trimestre pr�c�dent. 																																	  */
/*																																							  */
/* Ce programme est divis� en 5 parties :																													  */																													      */
/* 		1- Pr�paration des donn�es : d�finition des cat�gories familiales et des foyers jeunes																  */
/*		2- S�lection, parmi les m�nages �ligibles au RSA et � la prime (cumul), des m�nages b�n�ficiaires en respectant la cible d'effectif Cnaf	  		  */
/*		3- S�lection, parmi les jeunes d�cohabitants et cohabitants �ligibles � la prime, des b�n�ficiaires jeunes en respectant la cible d'effectif Cnaf	  */
/*		4- S�lection des m�nages �ligibles manquants par cat�gorie familiale.																				  */
/*	Les jeunes cohabitants (c�libataires) sont trait�s s�par�ment et leur effectif est d�duit des cibles Cnaf des c�libataires.								  */
/*	Pour les m�nages avec une prime principale positive (prime_decohab >0), s�lection parmi les �ligibles des m�nages b�n�ficiaires en respectant les cibles   */
/*	d'effectifs Cnaf par cat�gories familiales. Pour �tre s�r de respecter les cibles "cumul" et "jeunes", on commence par tirer les recourants au RSA et les */
/*  jeunes. 																																				  */
/*		5- It�rations : lancement de plusieurs it�rations pour d�terminer le tirage m�dian																	  */
/*																																							  */
/* L'option recalcul=0 permet de conserver le recours simul� dans le sc�nario central.																		  */
/* L'option recalcul=1 r�alise un nouveau calcul de recours � la prime d'activit�.																			  */
/* L'option recalcul=2 conserve les foyers recourant du sc�nario central mais permet d'ajouter de nouveaux recourants si une r�forme de la prime d'activit�   */
/* augmente le nombre de foyers �ligibles, de sorte � avoir un taux de recours constant.																	  */
/**************************************************************************************************************************************************************/

options mprint;
/*Effet al�atoire si n�cessaire*/
%let effet_rsa=0;  
%let effet_prime=0; 
%let effet_jeune=0; 


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/* 														I- Pr�paration des donn�es et classement selon le typmen_prime								          */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*				1- Importation des cibles de la Cnaf												   		  												  */ 
/**************************************************************************************************************************************************************/

/*L'utilisateur doit renseigner les cibles des b�n�ficiaires de la prime d'activit� dans le fichier parametres.xls.
Les cibles pr�-remplies (par d�fault) dans le fichier correspondent � une hypoth�se de plein recours*/
proc import datafile="&chemin_Saphir_2017.\parametres.xls" out=cnaf dbms=xls replace;sheet="prime";getnames=yes; run;

data typfam quotas;
set cnaf;
if typfam_id ne . then output typfam;
else output quotas;
run;

/*Pour r�cup�rer les cibles 
	1) du nombre de foyers culmulant le b�n�fice du RSA et de la prime d'activit� 
	2) du nombre de foyers jeunes b�n�ficiant de la prime d'activit�*/
data _null_;
set quotas;
call symput ("quota_"||typfam,compress(nbfoy));
run;


/**************************************************************************************************************************************************************/
/*				2- Pr�paration des donn�es : regroupement par type de foyer RSA, cr�ation des variables de tri, regroupement des cohabitants entre hommes	  */
/*				   c�libataires et femmes c�libataires						   		  																		  */
/**************************************************************************************************************************************************************/

%macro typmen;
data donnees;
set scenario.rsa (keep=ident&acour. numfoyrsa wprm&asuiv4. rsa: prime: cprrsa nbpcrsa_t: sexe: agenq_prrsa bonus_t: elig_prime_decohab_t: nbpcpa_t:) ;
by ident&acour. numfoyrsa;


/**************************************************************************************************************************************************************/
/*		a. Classement par configuration familiale                                                                                                             */
/**************************************************************************************************************************************************************/

/*NB : les nbpcrsa sont calcul�es apr�s optimisation dans le programme 13*/
%do t=1 %to 4;

if cprrsa=0 then do;
	if nbpcrsa_t&t.=0 then do; 
		if sexe_prrsa="1" then typmen_prime_t&t.=1;			/*Homme seul sans enfant*/
		else if sexe_prrsa="2" then typmen_prime_t&t.=2; 	/*Femme seule sans enfant*/
		else typmen_prime_t&t.=10;							/*Inconnus*/
	end;

	else if nbpcrsa_t&t.=1 then typmen_prime_t&t.=3; 		/*Isol� 1 enfant*/
	else if nbpcrsa_t&t.=2 then typmen_prime_t&t.=4; 		/*Isol� 2 enfants*/
	else if nbpcrsa_t&t.>=3 then typmen_prime_t&t.=5 ; 		/*Isol� 3 enfants ou plus*/
	else typmen_prime_t&t.=10;								/*Inconnus*/
end;

else if cprrsa=1 then do;
	if nbpcrsa_t&t.=0 then typmen_prime_t&t.=6; 			/*Couple sans enfant*/
	else if nbpcrsa_t&t.=1 then typmen_prime_t&t.=7;		/*Couple 1 enfant*/
	else if nbpcrsa_t&t.=2 then typmen_prime_t&t.=8;		/*Couple 2 enfants*/
	else if nbpcrsa_t&t.>=3 then typmen_prime_t&t.=9;		/*Couple 3 enfants ou plus*/
	else typmen_prime_t&t.=10;								/*Inconnus*/
end;


/**************************************************************************************************************************************************************/
/*		b. Identification et d�compte des jeunes cohabitants                                                                                                  */
/**************************************************************************************************************************************************************/

%let n=&nb_max_pc.; 	/*pour la boucle sur les PC*/
	%do j=1 %to &n.;	/*boucle sur les PC*/
	cohab_t&t._&j. = 0;
	if prime_cohab_t&t._&j.>0 then cohab_t&t._&j.=1;
	%end;

jeune=(agenq_prrsa>=18 & agenq_prrsa<=25); if jeune='.' then jeune=0;
cohab_t&t.= sum(of cohab_t&t._1-cohab_t&t._&n.);  								/*nombre de jeunes cohabitants par foyer RSA avant optimisation*/
jeune_elig_t&t.= (prime_cohab_pr_t&t.>0)!((prime_decohab_pr_t&t.>0)*(jeune>0)); /*ajout des jeunes d�cohabitants*/ 
prime_jeune_pr_t&t. = (prime_cohab_pr_t&t.) + (prime_decohab_pr_t&t.)*(jeune>0);

if prime_cohab_pr_t&t.>0 then celib_jeune_t&t. = 1; 	/*c�libataires jeunes : les faire recourir en 1er pour compenser le manque d'�ligibles c�libataires*/
else if (prime_decohab_pr_t&t.>0) & (jeune>0) & (typmen_prime_t&t. in ('1','2')) then celib_jeune_t&t. = 1;
else celib_jeune_t&t. = 0;


/**************************************************************************************************************************************************************/
/*		c. Cr�ation des variables pour trier sur les montants                                                                                                 */
/**************************************************************************************************************************************************************/

cumul_t&t.=((prime_pr_t&t.>0)&(rsa_pr_t&t.>0)); 
tri_rsa_t&t.=max(0,RSA_pr_t&t.) ;
tri_prime_t&t.=max(0, prime_pr_t&t.);
tri_jeune_t&t.=max(0, prime_jeune_pr_t&t.);


/**************************************************************************************************************************************************************/
/*		d. Classement des jeunes cohabitants entre hommes c�libataires et femmes c�libataires             	                                                  */
/**************************************************************************************************************************************************************/

if jeune_elig_t&t.=1 then do;	
	if cohab_t&t. = 1 then do;						
		%do k=1 %to &n.; 
		if ((prime_cohab_t&t._&k.>0) & (sexe_pcrsa&k.="1")) then typmenj_1_t&t.=1;		/*homme seul sans enfant*/
		else if ((prime_cohab_t&t._&k.>0) & (sexe_pcrsa&k.="2")) then typmenj_2_t&t.=1; /*femme seule sans enfant*/
		%end;
	end;
end;
%end; 
run;

%mend; %typmen;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/* 	  II. S�lection des foyers qui cumulent prime et RSA (de sorte � maximiser le recours au RSA socle tout en respectant l'effectif observ� par la Cnaf))    */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%macro recours_rsa;
/*On consid�re que les recours au RSA et � la prime sont li�s car un b�n�ficiaire du RSA b�n�ficie automatiquement de la prime s'il est �ligible*/

/**************************************************************************************************************************************************************/
/*				1- Tri selon une part al�atoire, le montant de prime et l'�ligibilit� au RSA		  		  												  */ 
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*Etape 1 : on trie la table en fonction d'une part al�atoire et selon les montants et on fait recourir tous les foyers �ligibles au RSA seulement		 	  */
/**************************************************************************************************************************************************************/

%do t=1 %to 4 ;
proc sql undo_policy=none;
   create table donnees as 
   select *,  max(tri_rsa_t&t.) as max_rsa_t&t., min(tri_rsa_t&t.) as min_rsa_t&t.
   from donnees group by cumul_t&t. order by cumul_t&t.  ;
quit;
%end ;

data donnees_rsa (drop = min: max:) ;  set donnees ;
%do t=1 %to 4 ;
	if tri_prime_t&t.>0 & cumul_t&t.>0  then rsa_0_1_t&t.= (tri_rsa_t&t.-min_rsa_t&t.)/(max_rsa_t&t.-min_rsa_t&t.); 
	alea_rsa_t&t.=sum(ranuni(1), rsa_0_1_t&t.*&effet_rsa.); 
	recours_rsa_t&t.=0; if RSA_pr_t&t.>0 & prime_pr_t&t.=0 then recours_rsa_t&t.=1; /*Pour les recourants au RSA socle seul, on est en plein recours*/
%end;
run ;


/**************************************************************************************************************************************************************/
/*				2- Recours des foyers cumulant RSA et prime											  		  												  */ 
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*Etape 2 : on fait recourir les foyers �ligibles au cumul RSA/prim d'activit�:																				  */
/*			a. On cale chaque trimestre sur le nombre constat� de foyers qui cumulent par la Cnaf															  */
/* 		On classe en fonction du recours des trimestres pr�c�dents.																							  */
/* 		Pour maximiser la masse financi�re du RSA, on peut �galement faire varier la variable &effet_rsa. d�finie en d�but de programme (permet d'effectuer   */
/*		tri sur les montants.																																  */ 	
/*			b. Une fois que l'on a d�fini le recours pour tous les foyers qui cumulent RSA et prime, on fait recourir tous ceux qui sont �ligibles au RSA     */
/* 		seulement   																																		  */
/**************************************************************************************************************************************************************/

data table_rsa_t1; set donnees_rsa ; run;
%do t=1 %to 4;

	proc sort data=table_rsa_t&t.; 
	  by %do i=1 %to %eval (&t.-1); descending recours_rsa_t%eval(&t.-&i.) %end;
	   descending alea_rsa_t&t.; 
	run;

	data table_rsa_t&t ;
	set table_rsa_t&t.(where=(cumul_t&t.>0));
	by  %do i=1 %to %eval (&t.-1); descending recours_rsa_t%eval(&t.-&i.) %end;
		descending alea_rsa_t&t.;
	retain quota 0 ;
	quota=quota+wprm&asuiv4. ;
	if quota>=&quota_cumul. then do ; recours_rsa_temp_t&t.=0; end  ;
    else recours_rsa_temp_t&t.=1;
	run ;

	proc sort data=table_rsa_t&t.; by ident&acour. numfoyrsa; run;
	proc sort data=donnees_rsa; by ident&acour. numfoyrsa; run;

	data table_rsa_t%eval(&t.+1);
	merge table_rsa_t&t.(keep=ident&acour. numfoyrsa recours_rsa_temp_t&t.) donnees_rsa ;
	by ident&acour. numfoyrsa;
	if recours_rsa_temp_t&t. ne '.' then recours_rsa_t&t.=recours_rsa_temp_t&t.; /*n�cessaire � cette �tape mais attention : la table t+1 sera tronqu�e ensuite donc il faut r��crire cette instruction � la fin de la boucle*/
	run;

%end;

data recours_rsa (drop=recours_rsa_temp:);
merge donnees_rsa %do t=1 %to 4; table_rsa_t&t. (keep=ident&acour. numfoyrsa recours_rsa_temp_t&t.) %end;; /*Attention au double ;*/
by ident&acour. numfoyrsa;
%do t=1 %to 4; if recours_rsa_temp_t&t. ne '.' then recours_rsa_t&t.=recours_rsa_temp_t&t. ; %end; /*c'est ici que l'on r��crit l'instruction qui, plus haut, marchait temporairement*/
run;

%mend;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/* 				III. S�lection des b�n�ficiaires jeunes cohabitants (class�s � tort dans le cat�gorie du m�nage d'origine) et d�cohabitants 				  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Les jeunes d�cohabitants "elig_prime_decohab" constituent d�j� leur propre foyer RSA/prime et sont bien comptabilis�s dans les typmen c�libataires ou	  */ 
/* couples sans enfant : leur recours est trait� dans l'�tape 3 avec la mise en commun. 																	  */	
/* Pour eux, la variable recours_jeune servira � s�lectionner les jeunes d�cohabitants recourants ou les m�nages avec un jeune cohabitant recourant et une    */ 
/* prime positive en priorit�.																																  */
/* Les jeunes encore comptabilis�s dans le foyer RSA/prime de leurs parents sont �tudi�s dans le cas "elig_prime_cohab" : pour bien comptabiliser ces foyers, */
/* leur recours est d�termin� par cette �tape et leur effectif sera d�compt� des cibles Cnaf utilis�es dans la mise en commun. 								  */
/**************************************************************************************************************************************************************/

%macro recours_jeune;

/**************************************************************************************************************************************************************/
/*				1- Tri des jeunes selon une part al�atoire et le montant de prime			  		  		  												  */ 
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Etape 1 : on trie les jeunes selon les montants et l'al�a																								  */
/**************************************************************************************************************************************************************/

%do t=1 %to 4 ;
proc sql undo_policy=none;
   create table donnees as 
   select *,  max(tri_jeune_t&t.) as max_jeune_t&t., min(tri_jeune_t&t.) as min_jeune_t&t.
   from donnees group by jeune_elig_t&t. order by jeune_elig_t&t.;
quit;
%end;

data prime_jeune (drop = min: max:);  set donnees;
%do t=1 %to 4;
	if tri_jeune_t&t.>0 & jeune_elig_t&t.>0  then primej_0_1_t&t.= (tri_jeune_t&t.-min_jeune_t&t.)/(max_jeune_t&t.-min_jeune_t&t.); 
	alea_jeune_t&t.=sum(ranuni(-1), primej_0_1_t&t.*&effet_jeune.);
%end;
run ;

data table_jeune_t1; set prime_jeune; run;

%do t=1 %to 4;
	proc sort data=table_jeune_t&t.; 
	by cumul_t&t.
	   descending jeune_elig_t&t. 
	   descending celib_jeune_t&t.		/*les c�libataires sont privil�gi�s pour pallier le manque de femmes c�libataires �ligibles � la prime*/
	%do i=1 %to %eval (&t.-1); descending recours_jeune_t%eval(&t.-&i.) %end; 
	descending alea_jeune_t&t.; 
	run;

/**************************************************************************************************************************************************************/
/*				2- Recours des foyers jeunes												  		  		  												  */ 
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Etape 2 : on fait recourir les foyers jeunes �ligibles en calant chaque trimestre sur le nombre constat� de foyers jeunes qui recourent � la prime.        */
/* On classe en fonction du recours au RSA, du statut (les c�libataires sont privil�gi�s pour pallier le manque de femmes c�libataires �ligibles), du reccours*/
/* le trimestre pr�c�dent.																														  			  */ 	
/**************************************************************************************************************************************************************/

	data table_jeune_t&t ;
	set table_jeune_t&t.(where=(jeune_elig_t&t.>0));
	by  cumul_t&t. descending celib_jeune_t&t.
		%do i=1 %to %eval (&t.-1); descending recours_jeune_t%eval(&t.-&i.) %end;
		descending alea_jeune_t&t.;
	retain quota 0 ;
	quota=quota+wprm&asuiv4. ;
	if quota>=&quota_jeune. then do ; recours_jeune_t&t.=0; end  ;
    else recours_jeune_t&t.=1;
	run ;

	proc sort data=table_jeune_t&t.; by ident&acour. numfoyrsa; run;
	proc sort data=prime_jeune; by ident&acour. numfoyrsa; run;
	
	data table_jeune_t%eval(&t.+1);
	merge table_jeune_t&t.(keep=ident&acour. numfoyrsa %do i=1 %to &t.; recours_jeune_t&i. %end;) prime_jeune;
	by ident&acour. numfoyrsa;
	if recours_jeune_t&t.='.' then recours_jeune_t&t.=0;
	run;
%end;

data recours_jeune;
merge prime_jeune
%do t=1 %to 4; table_jeune_t&t. (keep=ident&acour. numfoyrsa recours_jeune_t&t.) %end;;
by ident&acour. numfoyrsa;
%do t=1 %to 4;  if recours_jeune_t&t.='.' then recours_jeune_t&t.=0; %end;
run;

proc sort data=recours_rsa; by ident&acour. numfoyrsa; run;
proc sort data=recours_jeune; by ident&acour. numfoyrsa; run;

data recours_tri;
merge recours_jeune recours_rsa (keep=ident&acour. numfoyrsa %do t=1 %to 4; recours_rsa_t&t. %end;);
by ident&acour. numfoyrsa;
run;

/*D�compte des foyers jeunes cohabitants c�libataires hommes et femmes pour les d�duire des cibles CNAF (les cohabitants ont d�j� un bon typmen)*/
%do t=1 %to 4;
	proc means data=recours_jeune noprint; var wprm&asuiv4. ; where prime_jeune_pr_t&t.>0 & recours_jeune_t&t.>0 & typmenj_1_t&t.>0;
		output out=temporaire_1_t&t. (drop=_TYPE_ _FREQ_) sum=quota_j_1_t&t./NOINHERIT; run;
	proc means data=recours_jeune noprint; var wprm&asuiv4. ; where prime_jeune_pr_t&t.>0 & recours_jeune_t&t.>0 & typmenj_2_t&t.>0;
		output out=temporaire_2_t&t. (drop=_TYPE_ _FREQ_) sum=quota_j_2_t&t./NOINHERIT; run;
%end;

%mend;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/* 									III-  Mise en commun pour les m�nages avec prime_decohab >0 : cumul et jeunes en priorit� 							      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%macro recours_prime ;

/**************************************************************************************************************************************************************/
/*				1- Tri des foyers �ligibles selon une part al�atoire et le montant de prime			  		  		  										  */ 
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Etape 1 : on trie les foyers eligibles selon le montant et l'al�a																			 			  */
/**************************************************************************************************************************************************************/

%do t=1 %to 4 ;
proc sql undo_policy=none;
   create table donnees as 
   select *,  max(tri_prime_t&t.) as max_prime_t&t., min(tri_prime_t&t.) as min_prime_t&t.
   from donnees group by typmen_prime_t&t. order by typmen_prime_t&t. ;
quit;
%end ;

data donnees_prime (drop = min: max:) ;  set donnees;
%do t=1 %to 4 ;
	if tri_prime_t&t.>0 then prime_0_1_t&t. = (tri_prime_t&t. - min_prime_t&t.)/(max_prime_t&t. - min_prime_t&t.); 
	alea_prime_t&t.=sum(ranuni(-1), prime_0_1_t&t.*&effet_prime.); 
%end;
run ;

proc sort data=donnees_prime; by ident&acour. numfoyrsa; run;
proc sort data=recours_tri; by ident&acour. numfoyrsa; run;

data donnees_prime;
merge donnees_prime recours_tri (keep=ident&acour. numfoyrsa %do t=1 %to 4; recours_jeune_t&t. recours_rsa_t&t. typmenj_1_t&t. typmenj_2_t&t. %end;);
by ident&acour. numfoyrsa;
%do t=1 %to 4;
decohab_pr_t&t. = wprm&asuiv4.*(prime_decohab_pr_t&t.>0); /*Indicatrice du nombre de personnes ayant une prime decohab>0*/
%end;
run;

/**************************************************************************************************************************************************************/
/*				2- Recours des foyers �ligibles												  		  		  												  */ 
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Etape 2 : on fait recourir en priorit� les foyers �ligibles � la prime qui cumulent avec le RSA, puis les foyers jeunes, c-�-d les foyers qui sont jeunes  */ 
/* eux-m�mes ou qui ont un "sous-foyer" jeune cohabitant qui recourt.																						  */
/* Par l�, on veut faire recourir tous ceux qu'on a d�j� choisi pr�c�demment, et �viter pour les familles le fait d'avoir un foyer "noyau" qui ne recourt pas */
/* et le jeune cohabitant qui recourt (ou inversement).																										  */
/*																																							  */
/* Ce recours ne prend en compte que les m�nages qui ont une prime principale >0 (les prime_cohab sont ajout�es par la suite pour �viter les doubles comptes) */
/**************************************************************************************************************************************************************/


data table_prime_t1; set donnees_prime; run;

/**************************************************************************************************************************************************************/
/*		a. Cr�ation de la table de marges 				                                                                                                      */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Mise � jour des tables : rep�rage des sous-effectifs dans saphir et bascule si besoin d'une case � l'autre ; 		  									  */ 
/* Mise � jour des cibles c�libataires Homme/Femme en soustrayant le recours des jeunes cohabitants															  */
/**************************************************************************************************************************************************************/

	%do t=1 %to 4;

	data _null_; set temporaire_1_t&t.; call symput('quota_j_1',quota_j_1_t&t.); run;
	data _null_; set temporaire_2_t&t.; call symput('quota_j_2',quota_j_2_t&t.); run;
	proc means data=donnees_prime noprint; var decohab_pr_t&t.; class typmen_prime_t&t. ;
	output out=prime_t&t. (drop=_TYPE_ _FREQ_ where=(typmen_prime_t&t. ne .)) sum=nbfoy_elig_decohab_t&t./NOINHERIT; run;

	proc sort data=typfam; by typfam_id; run;
	proc sort data=prime_t&t.; by typmen_prime_t&t.; run;

	data cnaf_t&t.; 	/*Nombre d'�ligibles saphir vs. cibles cnaf : rep�rer les sous-effectifs dans saphir*/
	merge typfam (rename=(typfam_id=typmen_prime_t&t.)) prime_t&t. ; by typmen_prime_t&t.;
	if typmen_prime_t&t. = 1 then nbfoy = round(nbfoy - &quota_j_1.,1); /*Soustraction des cibles de c�libataires d�j� atteintes (les jeunes cohabitants) pour 
																		  comparer les "d�cohabitants" aux cibles*/
	if typmen_prime_t&t. = 2 then nbfoy = round(nbfoy - &quota_j_2.,2);	
	if nbfoy_elig_decohab_t&t. = . then nbfoy_elig_decohab_t&t. = 0;
	sous_eff=max(0,round(nbfoy-nbfoy_elig_decohab_t&t.,1));
	run;

	data _null_;
	set cnaf_t&t.;
	%do j=1 %to 10;
		if typmen_prime_t&t. = &j. then do; 
		call symput(cats('sous_eff', &j.), sous_eff);
		call symput(cats('nbfoy', &j.), nbfoy);
		end;
	%end;
	run;

	proc sort data=cnaf_t&t. ; by typmen_prime_t&t.; run;
	proc sort data=table_prime_t&t.;by typmen_prime_t&t.; run;

/**************************************************************************************************************************************************************/
/* Cr�ation de la table de marges et bascule des sous-effectifs												  	 		  									  */ 
/* 		- On bascule les personnes isol�es vers les couples de m�me nature ; par exemple : celibataire sans enfant => couple sans enfant 					  */
/* 		- On rebascule femmes et inconnus vers couples sans enfants plut�t que les hommes c�libataires (taux de recours effectif tr�s faible pour les couples */
/* 		et �lev� pour les hommes c�libataires).																									     		  */
/* 		- On rebascule les isol�es 3 enfants et plus vers les couples 3 enfants et plus																		  */
/**************************************************************************************************************************************************************/

	
	data marges; 
	merge table_prime_t&t. cnaf_t&t.; 
	by typmen_prime_t&t.;
	nbfoy= nbfoy+(&sous_eff1.+&sous_eff2.+&sous_eff10.)*(nbfoy=&nbfoy6.) + &sous_eff3.*(nbfoy=&nbfoy7.) + &sous_eff4.*(nbfoy=&nbfoy8.) + &sous_eff5.*(nbfoy=&nbfoy9.);
	run;


/**************************************************************************************************************************************************************/
/*		b. Recours final pour les foyers 				                                                                                                      */
/**************************************************************************************************************************************************************/

/*Recours_jeune pour les cohabitants, recours_principal pour les autres*/
	proc sort data=marges; 
	by typmen_prime_t&t. 
	   descending recours_rsa_t&t.				/* On choisit en premier les personnes qui cumulent */
	   cumul_t&t.								/* Pour �viter de choisir des �ligibles au cumul non s�lectionn�s dans la macro "recours rsa" et ne pas d�passer le cible cnaf*/
	   descending recours_jeune_t&t.			/* On choisit ensuite les foyers jeunes d�cohabitants et les foyers qui comportent un jeune cohabitant qui recourt � la prime */
	   jeune_elig_t&t.							/* Pour �viter de choisir des �ligibles � la prime jeune non s�lectionn�s dans la macro "recours jeune" */
 	   %do i=1 %to %eval(&t.-1); descending recours_prime_t%eval(&t.-&i.) %end; 	/* Les personnes recourant au trimestre pr�c�dent ont plus de chances de recourir */
       descending alea_prime_t&t.; 				/* Tri suivant l'al�a qui a une part plus ou moins variable*/
	run;

	data prime_nr_t&t.;
	set marges (where=(prime_decohab_pr_t&t.>0));
	by typmen_prime_t&t.  
       descending recours_rsa_t&t.
	   cumul_t&t.
	   descending recours_jeune_t&t.
	   jeune_elig_t&t.
	   %do i=1 %to %eval(&t.-1); descending recours_prime_t%eval(&t.-&i.) %end; 
       descending alea_prime_t&t.; 
	retain quota 0;
	if first.typmen_prime_t&t. then quota=0;
	quota=quota+wprm&asuiv4. ;
	if quota>=nbfoy then do ; recours_principal_t&t.=0; end;
    else recours_principal_t&t.=1;
	run;

	proc sort data=table_prime_t&t.; by ident&acour. numfoyrsa; run;
	proc sort data=prime_nr_t&t.; by ident&acour. numfoyrsa; run;

	data table_prime_t%eval(&t.+1);
	merge table_prime_t&t. prime_nr_t&t.(keep=ident&acour. numfoyrsa recours_principal_t&t.);
	by ident&acour. numfoyrsa;
	if recours_principal_t&t.=. then recours_principal_t&t.=0;
	recours_prime_t&t. = max(recours_principal_t&t., recours_jeune_t&t.); 
	run;
%end;

/*Calcul de la prime avec non-recours*/
data recours_&iter.;
	merge scenario.rsa table_prime_t5 (keep=ident&acour. numfoyrsa recours_prime_t: recours_principal_t: recours_jeune_t: recours_rsa_t: typmen: cumul_t: alea: typmenj: jeune jeune_elig_t: cohab_t:);
	by ident&acour. numfoyrsa;

	%do t=1 %to 4; 
	prime_t&t.=prime_pr_t&t.*recours_prime_t&t.;
	rsa_t&t.=rsa_pr_t&t.*recours_rsa_t&t.;
	prime_cohab_t&t.=prime_cohab_pr_t&t.*recours_prime_t&t.;
	prime_decohab_t&t.=prime_decohab_pr_t&t.*recours_prime_t&t.;
	%end; 

	prime=sum(of prime_t1-prime_t4) ; 
	rsa=sum(of rsa_t1-rsa_t4); 
	rsa_pa=sum(prime,rsa); 
	prime_cohab=sum(of prime_cohab_t1-prime_cohab_t4) ;
	prime_decohab=sum(of prime_decohab_t1-prime_decohab_t4) ;
run;

	proc means data=recours_&iter. noprint nway; var prime;
	output out=somme_&iter.(drop=_TYPE_ _FREQ_) sum=;
	weight wprm&asuiv4.;
	run;
	data somme_&iter.; set somme_&iter.; tirage=&iter.; run;
	%if &iter.=1 %then %do; data recap_nr; set somme_&iter.(keep=tirage prime);run; %end;
	%else %do; data recap_nr; set recap_nr somme_&iter.(keep=tirage prime);run; %end;

%mend;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/* 																		IV- It�rations 																   		  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
%macro iteration(nb);

	%recours_rsa;

%do iter=1 %to &nb. ;	/*on effectue &nb it�rations*/
	dm log 'clear' editor;
	%recours_jeune;
	%recours_prime;
%end;

/*D�termination du tirage m�dian*/
proc sort data=recap_nr; by prime; run;
%let picked=%sysevalf((&nb.+1)/2,integer);
data _NULL_; set recap_nr; if _N_=max(1,&picked.) then call symput("tirage",compress(tirage)); run;

data scenario.non_recours; /*contient le statut de recours de chacun des foyers RSA*/
set recours_&tirage.(keep=ident&acour. numfoyrsa recours_: typmen: cumul_t: alea: typmenj: jeune jeune_elig_t: cohab_t: alea_: rsa: prime: rsa_prime_cumul: wprm&asuiv4.);
run;
%mend;


%macro simul_recours ;
%if &recalcul.= 1 %then %do ; 
	%iteration(15); /*utiliser un nombre impair d'it�rations pour pouvoir calculer la m�diane*/
%end ;

%else %if &recalcul.= 0 %then %do ; /*on r�cup�re les infos de la table non_recours du sc�nario central*/
  proc sort data=central.non_recours out=non_rec ;by ident&acour. numfoyrsa;run;
  data scenario.non_recours (keep=ident&acour. numfoyrsa recours_: typmen: typmen_prime_t: jeune_elig_t: rsa: prime: rsa_pa:  wprm&asuiv4. alea_:);
  merge scenario.rsa non_rec (keep=ident&acour. numfoyrsa recours_: typmen_prime_t: alea_: jeune_elig_t:);
  by ident&acour. numfoyrsa;
  %macro boucle;
  %do t=1 %to 4;
  prime_t&t.=prime_pr_t&t. * recours_prime_t&t.;
  prime_cohab_t&t.=prime_cohab_pr_t&t. * recours_prime_t&t.;
  prime_decohab_t&t.=prime_decohab_pr_t&t. * recours_prime_t&t.;
  rsa_t&t.=rsa_pr_t&t.* recours_rsa_t&t. ;
  rsa_prime_cumul_t&t.=sum(rsa_t&t.,prime_t&t.); 
  %end;
  %mend; %boucle;
  prime=sum(of prime_t1-prime_t4) ; 
  rsa=sum(of rsa_t1-rsa_t4); 
  rsa_pa=sum(prime,rsa); 
  prime_cohab=sum(of prime_cohab_t1-prime_cohab_t4) ;
  run;
%end ;
%mend ; %simul_recours ;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/
