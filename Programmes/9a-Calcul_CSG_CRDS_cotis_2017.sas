
/**************************************************************************************************************************************************************/
/*                                									SAPHIR E2013 L2017                                          							  */
/*                                     									PROGRAMME 9a                                           								  */
/*     							Calcul sur bar�me de la CSG, de la CRDS, des cotisations sociales sur les revenus 2017                    					  */
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
/* nouveu revenu net est calcul�.																															  */ 	
/*																																							  */
/* Les revenus concern�s sont les suivant :  																												  */
/* 		- Retraites (CSG, CRDS et Casa)   																												   	  */
/* 		- Ch�mage (CSG et CRDS)																																  */
/*		- Salaires du priv� (CSG, CRDS et cotisations sociales)																								  */
/*		- Revenus des ind�pendants (CSG, CRDS et cotisations sociales)																						  */
/*																																							  */
/* Ce programme utilise les macros d�finies dans le programme 8a et d�termine les cotisations sociales, la CSG et la CRDS pour l'ann�e 2017.				  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                      										I. Pr�paration des donn�es                        										      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=scenario.impot_fip_r&asuiv2. (keep=ident&acour. declar rfr_recalc2 dse part) 
out=imposable&asuiv2.; by ident&acour. declar; run; 
proc sort data=saphir.cotis out=cotis; by ident&acour. declar; run; 


data cotis;
merge cotis (in=a) imposable&asuiv2. (keep=ident&acour. declar rfr_recalc2 dse part) ; by ident&acour. declar; if a;

/*Tx_ret tx_cho : r�gime d'assujettissement (exon�ration, taux r�duit, taux plein) pour les revenus de remplacement*/
if (rfr_recalc2=<(&&seuil_exo_csg&asuiv4.+max(part-1,0)*2*&&seuil_exo_csg_demipart&asuiv4.) ! info_fip=0) then tx_ret&asuiv4.=1;	/*exon�ration*/
else do;
    if rfr_recalc2=<(&&seuil_tx_red&asuiv4.+max(part-1,0)*2*&&seuil_tx_red_demipart&asuiv4.) then tx_ret&asuiv4.=2;					/*taux r�duit*/
    else tx_ret&asuiv4.=3; 																											/*taux plein*/
end;
tx_cho&asuiv4.=tx_ret&asuiv4.;
/*L'exon�ration pour les revenus du ch�mage inf�rieurs au SMIC est prise en compte dans la macro calculcotiz*/

run;

proc sort data=cotis; by ident&acour. noi; run; 


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                      										 II. Calcul CSG, CRDS, cotisations                 					  						  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%calculcotiz(an=&asuiv4.);


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*              											III. Ajout des nouveaux revenus � MENAGE_PREST                       						      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc means data =cotis&asuiv4. noprint;
by ident&acour.;
var ztsai&asuiv4. revinded&asuiv4. zperi&asuiv4. 
zsalpi&asuiv4. zchopi&asuiv4. zrstpi&asuiv4. revindep&asuiv4. 
zrstbi&asuiv4. zchobi&asuiv4. zsalbi&asuiv4. zragbi&asuiv4. zricbi&asuiv4. zrncbi&asuiv4.
csecu_sal&asuiv4. CSecu_pat&asuiv4. CSecu_Cho&asuiv4. csecu_rnc&asuiv4. csecu_ric&asuiv4. csecu_rag&asuiv4.
CSS_pat&asuiv4. css_cho&asuiv4. CSS_indep&asuiv4. css_sal&asuiv4.
CSG_act&asuiv4. CSG_remp&asuiv4. CSG_rst&asuiv4. CRDS_act&asuiv4. CRDS_remp&asuiv4. Retr_Chom_act&asuiv4. casa_rst&asuiv4. CRDS_cho&asuiv4. VIVEA&asuiv4.;
output out=revi_men&asuiv4. (drop = _TYPE_ _FREQ_) 
sum(ztsai&asuiv4. revinded&asuiv4. zperi&asuiv4. zsalpi&asuiv4. zchopi&asuiv4. zrstpi&asuiv4. revindep&asuiv4.
zrstbi&asuiv4.  zchobi&asuiv4. zsalbi&asuiv4. zragbi&asuiv4. zricbi&asuiv4. zrncbi&asuiv4.
csecu_sal&asuiv4. CSecu_pat&asuiv4. CSecu_Cho&asuiv4. csecu_rnc&asuiv4. csecu_ric&asuiv4. csecu_rag&asuiv4.
CSS_pat&asuiv4. css_cho&asuiv4. CSS_indep&asuiv4. css_sal&asuiv4.
CSG_act&asuiv4. CSG_remp&asuiv4. CSG_rst&asuiv4. CRDS_act&asuiv4. CRDS_remp&asuiv4. Retr_Chom_act&asuiv4. casa_rst&asuiv4. CRDS_cho&asuiv4. VIVEA&asuiv4.)
=ztsam&asuiv4. revindedm&asuiv4. zperm&asuiv4. zsalpm&asuiv4. zchopm&asuiv4. zrstpm&asuiv4. revindepm&asuiv4. 
zrstbm&asuiv4.  zchobm&asuiv4. zsalbm&asuiv4. zragbm&asuiv4. zricbm&asuiv4. zrncbm&asuiv4.
csecu_sal&asuiv4. CSecu_pat&asuiv4. CSecu_Cho&asuiv4. csecu_rnc&asuiv4. csecu_ric&asuiv4. csecu_rag&asuiv4.
CSS_pat&asuiv4. css_cho&asuiv4. CSS_indep&asuiv4. css_sal&asuiv4.
CSG_act&asuiv4. CSG_remp&asuiv4. CSG_rst&asuiv4. CRDS_act&asuiv4. CRDS_remp&asuiv4. Retr_Chom_act&asuiv4. casa_rst&asuiv4. CRDS_cho&asuiv4. VIVEA&asuiv4. ;
run;

proc sort data=revi_men&asuiv4.; by ident&acour. ; run;

/*Ajout � la table MENAGE_SAPHIR*/
data scenario.menage_prest;
merge scenario.menage_prest revi_men&asuiv4.;
by ident&acour.;
run;

/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*              												IV. Ajout des nouveaux revenus � INDIV_PREST                        						  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=scenario.indiv_prest; by ident&acour. noi; run;
proc sort data=cotis&asuiv4.; by ident&acour. noi; run;

data scenario.indiv_prest;
merge scenario.indiv_prest
cotis&asuiv4.(keep=ident&acour. noi csecu_sal&asuiv4. CSecu_pat&asuiv4. CSecu_Cho&asuiv4. csecu_rnc&asuiv4. csecu_ric&asuiv4. csecu_rag&asuiv4.
CSS_pat&asuiv4. css_cho&asuiv4. CSS_indep&asuiv4. css_sal&asuiv4. unedic_sal&asuiv4.
CSG_act&asuiv4. CSG_sal&asuiv4. CSG_rag&asuiv4. CSG_ric&asuiv4. CSG_rnc&asuiv4. CSG_remp&asuiv4. CSG_rst&asuiv4. tx_ret&asuiv4. CRDS_act&asuiv4. CRDS_remp&asuiv4. Retr_Chom_act&asuiv4. tx_ret: tx_cho:
revactd&asuiv4. zchoi&asuiv4. ztsai&asuiv4. zperi&asuiv4. REVINDED&asuiv4.
CSG_ric&asuiv4. CSG_rnc&asuiv4. CRDS_ric&asuiv4. CRDS_rnc&asuiv4.
    revactp&asuiv4._t: zchopi&asuiv4._t: zrstpi&asuiv4._t: zsalpi&asuiv4._t: zragpi&asuiv4._t: zricpi&asuiv4._t: zrncpi&asuiv4._t:
    revindep&asuiv4. revactp&asuiv4.
    zsali&asuiv4. zchoi&asuiv4. zrsti&asuiv4. zragi&asuiv4. zrici&asuiv4. zrnci&asuiv4.
    zsalbi&asuiv4. zchobi&asuiv4. zrstbi&asuiv4. zragbi&asuiv4. zricbi&asuiv4. zrncbi&asuiv4.
    zsalpi&asuiv4. zchopi&asuiv4. zrstpi&asuiv4. zragpi&asuiv4. zricpi&asuiv4. zrncpi&asuiv4. );
by ident&acour. noi;
run;

/*Nettoyage de WORK*/
proc datasets library=work;delete cotis cotis&asuiv4. imposable&asuiv4.;run;quit;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

