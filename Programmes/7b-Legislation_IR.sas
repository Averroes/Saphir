

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 7b                                         			     			      */
/*                     										L�gislation de l'impot sur le revenu															  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Les imp�ts sont calcul�s au niveau du foyer fiscal, � partir des cases vieillies des d�clarations fiscales de la table foyer. Pour les individus � non     */
/* appari�s � un traitement particulier est r�alis� � travers le calcul d�un imp�t simplifi� (programme 10).  												  */
/* L�imp�t sur le revenu est calcul� sur la base des d�clarations d�imp�t sur le revenu 2013 (ERFS 2013) en appliquant la l�gislation en vigueur pour l�imp�t */
/* sur le revenu. Les revenus consid�r�s sont ceux de l'ann�es N-1.																							  */
/*																																							  */
/* Contrairement aux autres transferts, l�unit� de r�f�rence (foyer fiscal) n�est pas reconstruite : les foyers fiscaux retenus sont ceux qui correspondent   */	
/* aux d�clarations fiscales de la DGFiP. La composition des foyers fiscaux, qui peut faire l'objet de strat�gies d'optimisation, est donc celle de l'ERFS et */
/* n'est pas modifi�e dans Saphir. Les d�clarations fiscales contiennent des informations sur les cr�dits et r�ductions d'imp�ts (heures de travail, salaires */
/* vers�s pour les services � la personne...). Ces cr�dits et r�ductions d'imp�ts pr�sents dans l'ERFS ne sont pas modifi�s pour adapter les donn�es � l'ann�e */
/* voulue car les choix et comportement d'optimisation ne sont pas pr�visibles. 																			  */
/*																																							  */
/* Ce programme d�finit les variables n�cessaires � la reconstruction de la l�gislation de l'impot sur le revenu 2016 sur les revenus 2015					  */
/**************************************************************************************************************************************************************/

%macro Parametres(evol_bareme);

    %global 

/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											I. D�claration des param�tres 		                									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/ 

            switch_ppe
            switch_compl_sant
               
            csg_pla_ded csg_pla_ded_def
            csg_pat_ded csg_pat_ded_def
            csg_pla_nod
            csg_pat_nod

            switch_int switch_div switch_pv switch_av max_av_pfl quotient_pv creation_PFO taux_PFO_int taux_PFO_div
            
            nb_tranches  nb_enf_max
            maj_taux abat_taux pen_abat_taux
            bar_taux_1 bar_taux_2 bar_taux_3 bar_taux_4 bar_taux_5
            bar_seuil_1 bar_seuil_2 bar_seuil_3 bar_seuil_4 bar_seuil_5
            plaf_qf_1 plaf_qf_2 plaf_qf_3 plaf_qf_4 plaf_qf_5 plaf_qf_6

            demi_part_vieux  sofipeche_ded_taux

            sal_abat_max pen_abat_max sal_abat_min pen_abat_min cho_abat_min 
            auto_abat_min auto_ca_vente_plaf auto_ca_service_plaf auto_vente_abat auto_service_abat auto_nc_abat
            rcm_abat_taux rcm_abat_forf_1 rcm_abat_forf_2 av_seul_abat av_couple_abat

            ba_rev_plaf 
            pen_alim_max 
            age_frais_max
            gro_rep_plaf
            abat_spe_age_plaf_1 abat_spe_age_plaf_2 abat_spe_age_mont_1 abat_spe_age_mont_2 abat_spe_enf_marie


            plaf_decote_celib 
            plaf_decote_couple 
            pente_decote_celib
            pente_decote_couple
            sofica_plaf sofipeche_seul_plaf sofipeche_couple_plaf
            cap_pme_couple_plaf_1 cap_pme_seul_plaf_1 cap_pme_couple_plaf_2 cap_pme_seul_plaf_2
            aide_creat_reduc  aide_creat_majo_handi
            fcpi_couple_plaf fcpi_seul_plaf fip_couple_plaf fip_seul_plaf fip_couple_corse_plaf fip_seul_corse_plaf
            int_repr_couple_plaf int_repr_seul_plaf college_reduc
            lycee_reduc etab_sup_reduc diff_agri_seul_plaf 
            diff_agri_couple_plaf
            prest_divorce_plaf
            sal_dom_plaf sal_dom_enf_charge_majo sal_dom_plaf_max sal_dom_1ere_emb_plaf sal_dom_inv_plaf
            age_long_sejour_plaf
            inv_loc_01_seul_plaf inv_loc_01_couple_plaf inv_loc_0103_seul_plaf inv_loc_0103_couple_plaf inv_loc_04_seul_plaf inv_loc_04_couple_plaf
            rente_survie_plaf rente_survie_enf_charge_majo 
            foret_cot_plaf foret_acq_seul_plaf foret_trav_seul_plaf foret_contr_seul_plaf foret_acq_couple_plaf foret_trav_couple_plaf foret_contr_couple_plaf
            dons_difficult_plaf monu_hist_plaf cga_frais_adh_plaf
            inv_dom_plaf protect_nat_plaf rest_immo_plaf env_plaf 
            prev_risque_seul_plaf prev_risque_couple_plaf prev_risque_pac_majo
            div_50_seul_plaf div_50_couple_plaf
            gros_equip_seul_plaf gros_equip_couple_plaf gros_equip_majo 
            int_pret_etud_plaf int_empr_seul_plaf int_empr_charge_majo
            garde_enf_plaf garde_enf_alt_plaf
             
            seuil_perc_avt_restit 
            seuil_perc_apt_restit 
            seuil_restit 
            rv_m50_abat rv_m60_abat rv_m70_abat rv_p70_abat
            age_seuil
            micfonc_abat_taux

            InvMeuNonPro_taux1
            InvMeuNonPro_taux2
            InvMeuNonPro_taux3
            InvMeuNonPro_taux4
            InvMeuNonPro_plaf

            auto_vente_abat
            auto_service_abat
            auto_nc_abat
            age_seuil
            rv_m50_abat
            rv_m60_abat
            rv_m70_abat
            rv_p70_abat

            pv_mob_taux pv_mob_taux_entr pv_pro_taux

            pv_cap_risque_taux
            pv_dom_taux1
            pv_dom_taux2
            pv_pea_taux
            pv_titre_taux1
            pv_titre_taux2
            pv_titre_taux3

            dons_difficult_taux
            dons_utipub_taux
            dons_utipub_plaf

            cot_syndic_plaf
            cot_syndic_taux
            sal_dom_taux
            diff_agri_taux
            divorce_taux
            fcpi_taux
            fip_taux
            fip_corse_taux
            fip_dom_taux fip_couple_dom_plaf fip_seul_dom_plaf

            sofica_plaf_taux
            sofica_ded_taux1
            sofica_ded_taux2
            cap_pme_taux1 cap_pme_taux2 cap_pme_taux3
            reprise_soc_taux 
            foret_acq_taux foret_rep_taux foret_cot_taux foret_ass_taux
            age_long_sejour_taux
            rente_survie_taux
            inv_loc_taux1
            inv_loc_taux2
            inv_loc_trav_taux1 inv_loc_trav_taux2 inv_loc_trav_taux3 inv_loc_trav_taux4
            protect_nat_taux
            sofipeche_plaf_taux sofipeche_ded_taux

            monu_hist_taux

            OM_plaf
            OM_plaf2
            OM_plaf3
            OM_plaf_specif1
            OM_plaf_specif2
            OM_plaf_specif3
            OM_taux1
            OM_taux2
            OM_taux3
            OM_taux4
            OM_taux5
            OM_taux6
            OM_taux7
            OM_lim1
            OM_lim2
            OM_lim3

            qualenv_plaf

            duflot_plaf_dec
            duflot_taux1 
            duflot_taux2

            scl_plaf_dec
            scl_met_bbc_taux1
            scl_met_nonbbc_taux1
            scl_OM_taux1

            scl_met_bbc_taux2 
            scl_met_nonbbc_taux2
            scl_OM_taux2

            scl_met_bbc_taux3 
            scl_OM_taux3

            rest_immo_taux1 rest_immo_taux2 rest_immo_taux3 rest_immo_taux4 rest_immo_taux5
            pv_etrangeres_taux1 pv_etrangeres_taux2
            bien_cult_taux

            ci_qualenvir_taux1 ci_qualenvir_taux2 ci_qualenvir_taux3 ci_qualenvir_taux4 ci_qualenvir_taux5
          
            ci_aidepers_hab_taux1
            ci_aidepers_hab_taux2
            ci_aidepers_hab_taux3
            droit_bail_taux
            garde_enf_taux
            int_pret_etud_taux
            int_empr_taux1 int_empr_taux2 int_empr_taux3 int_empr_taux4 int_empr_taux5 int_empr_taux6
            assur_loy_imp_taux
            prev_risque_taux

            pfl_avi pfl_int pfl_div taux_impot_forf
            
            abat_dom_taux1 abat_dom_plaf1 abat_dom_taux2 abat_dom_plaf2

            CEHR_taux1 CEHR_taux2 CEHR_seuil1 CEHR_seuil2

            niche_plaf_fixe niche_plaf_majo niche_plaf_taux
            
            ppe_foyer1 ppe_foyer2 ppe_foyer3
            ppe_indiv1 ppe_indiv2 ppe_indiv3 ppe_indiv4 ppe_indiv5
            ppe_mono ppe_isoleENF ppe_coupleENF ppe_seuil ppe_partiel
            ppe_taux1 ppe_taux2 ppe_taux3

            cidd_tx_1 cidd_tx_2 cidd_tx_3 cidd_tx_4 cidd_tx_5 cidd_tx_6      
            cidd_tx_1_b cidd_tx_3_b  cidd_tx_4_b cidd_tx_5_b cidd_tx_6_b
            
            plafond_cidd 
            majo_cidd 

            seuil_rfr_cidd 
            tx_cidd_bouquet 
            tx_cidd_seul 
            tx_cidd_unique 

            pv_abat_exp 
            switch_pvm

            switch_calc_elast

            taux_bspce_1
            taux_bspce_2
            pv_pea_taux_1
            pv_pea_taux_2
            pfl_pens_taux 
            pfl_pens_abat
            taux_PFO_int
            taux_PFO_div
            creation_PFO
            switch_pfo
            switch_redIR 
            seuil_redIR_1
            seuil_redIR_2
            seuil_redIR_dp
            taux_redIR 
            ;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											II. D�finition des param�tres  			               									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/ 

/**************************************************************************************************************************************************************/
/*				1- CSG sur les revenus du capital			                												     							  */
/**************************************************************************************************************************************************************/

/*NB: les param�tres en _def sont utilis�s pour remonter aux assiettes brutes et ne doivent pas �tre modifi�s dans les sc�narios de r�formes*/

    %let csg_pla_ded_def = 0.051 ; /*CSG deductible sur les revenus de placement (valeur par d�faut)*/
    %let csg_pla_ded     = 0.051 ; /*CSG deductible sur les revenus de placement*/
    %let csg_pla_nod     = 0.031 ; /*CSG non deductible sur les revenus de placement*/
  
    %let csg_pat_ded_def = 0.051 ; /*CSG deductible sur les revenus du patrimoine (valeur par d�faut)*/
    %let csg_pat_ded     = 0.051 ; /*CSG deductible sur les revenus du patrimoine*/
    %let csg_pat_nod     = 0.031 ; /*CSG non deductible sur les revenus du patrimoine*/


/**************************************************************************************************************************************************************/
/*				2- Prise en compte des mesures nouvelles		            												     							  */
/**************************************************************************************************************************************************************/

	/*Mesure HCAAM : suppression de l'exon�ration fiscale de la participation de l'employeur aux contrats collectifs de compl�mentaire sant�*/
    %let switch_compl_sant = 1;

    /*Suppression de la PPE*/
    %let switch_ppe = 0 ;

/**************************************************************************************************************************************************************/
/*				3- Mise au bar�me des RCM						            												     							  */
/**************************************************************************************************************************************************************/

    /*Pour mettre les rcm au bar�me*/
    %let switch_int = 1 ;
    %let switch_div = 1 ;
    %let switch_pv = 0 ;
    %let switch_av = 0 ;
    %let quotient_pv = 0 ;
    %let creation_PFO = 0 ;         /*PFO obligatoire au taux actuel des PFL (21 % dividendes et 24 % int�r�ts)*/
    %let taux_PFO_int = 0.24 ;
    %let taux_PFO_div = 0.21 ;
    %let max_av_pfl = 1000000000;  	/*Plafond de produit d'assurance vie � passer au PFL*/

    /*Nombre de tranches du bar�me de l'imp�t sur le revenu*/
    %let nb_tranches = 4 ;

    %let nb_enf_max = 8 ;

/**************************************************************************************************************************************************************/
/*				4- Actualisation de la l�gislation						            												     							  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Param�tres g�n�raux																									 		                      */
/**************************************************************************************************************************************************************/

    %let maj_taux= 1.25 ;        	/*majoration utilis�e dans plusieurs cas*/
    %let abat_taux = 0.10;          /*taux abattement de 10% (ou frais r��ls)*/


/**************************************************************************************************************************************************************/
/*		b. Bar�me de l'impot sur le revenu																						 		                      */
/**************************************************************************************************************************************************************/

    /*Taux marginaux du bar�me de l'imp�t sur le revenu*/
    %let bar_taux_1 = 0.14 ; 
    %let bar_taux_2 = 0.30 ; 
    %let bar_taux_3 = 0.41 ;
    %let bar_taux_4 = 0.45 ;

    /*Tranches du bar�me de l'imp�t sur le revenu*/
    %let bar_seuil_1 = %sysfunc(round(9700*&evol_bareme.));
    %let bar_seuil_2 = %sysfunc(round(26791*&evol_bareme.));
    %let bar_seuil_3 = %sysfunc(round(71826*&evol_bareme.));
    %let bar_seuil_4 = %sysfunc(round(152108*&evol_bareme.));

    /*Quotient familial*/ 
    %let plaf_qf_1 =  %sysfunc(round(1510*&evol_bareme.));        /*plafonnement quotient familial 1/2 part*/
    %let plaf_qf_2 =  %sysfunc(round(3562*&evol_bareme.));        /*plafonnement quotient familial 1/2 part suppl�mentaire*/
    %let plaf_qf_3 =  %sysfunc(round(902*&evol_bareme.));         /*plafonnement quotient familial 1/2 part*/ 
    %let plaf_qf_4 =  %sysfunc(round(1506*&evol_bareme.));        /*r�duction compl�mentaire pour 1/2 part invalides*/ 
    %let plaf_qf_5 = 0 ;
    %let plaf_qf_6 = %sysfunc(round(1682*&evol_bareme.)) ;        /*r�duction compl�mentaire pour 1/2 part veufs*/ 
 
    /*R�duction d'imp�t suppl�mentaire en cas de plafonnement du QF accord�e aux invalides, anciens combattants et personnes seules dont le dernier enfant 
	a au plus 25 ans*/
    %let demi_part_vieux = 0 ; 	/*suppression de la demi part pour personne ayant �lev� des enfants vivant seule mais ne les ayant pas �lev�s seule*/  


/**************************************************************************************************************************************************************/
/*		c. Revenus cat�goriels																									 		                      */
/**************************************************************************************************************************************************************/
 
    /*Salaires et retraites*/ 
    %let sal_abat_max =  %sysfunc(round(12169*&evol_bareme.)) ;   /*P0220 maximum abattement 10% traitements et salaires*/
    %let sal_abat_min =  %sysfunc(round(426*&evol_bareme.)) ;     /*P0240 minimum d�duction 10% traitements et salaires*/
    %let cho_abat_min =  %sysfunc(round(937*&evol_bareme.)) ;     /*P0284 d�duction forfait minimale pour demandeur d'emploi depuis plus d'1 an*/
    %let pen_abat_max =  %sysfunc(round(3711*&evol_bareme.)) ;    /*P0230 maximum d�duction 10% pensions et retraites*/
    %let pen_abat_min =  %sysfunc(round(379*&evol_bareme.)) ;     /*P0241 minimum d�duction 10% pensions*/
    %let pen_abat_taux = 0.10;

    /*Abattement sur rente viag�re*/
    %let rv_m50_abat = 0.70 ;    /*fraction imposable si le b�n�ficiaire avait moins de 50 ans au commencement du versement de la rente*/ 
    %let rv_m60_abat = 0.50 ;    /*fraction imposable si le b�n�ficiaire avait moins de 60 ans au commencement du versement de la rente*/ 
    %let rv_m70_abat = 0.40 ;    /*fraction imposable si le b�n�ficiaire avait moins de 70 ans au commencement du versement de la rente*/ 
    %let rv_p70_abat = 0.30 ;    /*fraction imposable si le b�n�ficiaire avait plus  de 70 ans au commencement du versement de la rente*/ 

    /*BIC et BNC*/
    %let auto_vente_abat = 0.71 ;      /*abattement forfaitaire correspondant aux charges pour les activit�s d'achat et vente*/
    %let auto_service_abat = 0.50 ;    /*abattement forfaitaire correspondant aux charges pour les activit�s de services*/
    %let auto_nc_abat = 0.34 ;         /*abattement forfaitaire correspondant aux charges pour les activit�s non commerciales*/

    %let auto_abat_min = 305;                               			/*E2000 abattement minimum pour r�gime micro*/
    %let auto_ca_vente_plaf = %sysfunc(round(82282*&evol_bareme.)) ;    /*E2001 plafond micro entreprise avec une activite de vente de marchandises*/
    %let auto_ca_service_plaf = %sysfunc(round(32933*&evol_bareme.));   /*plafond micro entreprise avec une activit� de prestation de service*/

    /*Revenus de capitaux mobiliers*/ 
    %let av_couple_abat = 9200;        	/*P0291 montant de l'abattement pour une assurance vie pour un couple*/
    %let av_seul_abat = 4600;          	/*P0290 montant de l'abattement pour une assurance vie pour une personne seule*/
    %let rcm_abat_taux = 0.4 ; 			/*taux de l'abattement sur les revenus d action au bar�me*/
    %let rcm_abat_forf_1 = 0; 			/*montant de l'abattement sur les revenus d actions CDV*/
    %let rcm_abat_forf_2 = 0; 			/*montant de l'abattement sur les revenus d actions MP*/

    /*R�gime micro-foncier*/
    %let micfonc_abat_taux = 0.30 ; 	/*Taux d'abattement correspondant aux frais sur le r�gime micro foncier*/


/**************************************************************************************************************************************************************/
/*		d. Revenu brut global																									 		                      */
/**************************************************************************************************************************************************************/
 
    %let ba_rev_plaf = %sysfunc(round(107718*&evol_bareme.));        	/*P0320 plafond du revenu global pour d�duction d�ficit BA*/

    /*Charges d�ductibles du revenu global  : frais d'accueil et pension alimentaire*/ 
    %let pen_alim_max = %sysfunc(round(5732*&evol_bareme.)) ;        	/*Abattement maximal sur les pensions alimentaires pour un enfant celibataire majeur*/   
    %let age_frais_max = %sysfunc(round(3406*&evol_bareme.));        	/*P0535 frais d accueil maximal pour les plus de 75 ans*/
    %let gro_rep_plaf = 25000 ; 										/*plafond des d�penses de grosses r�parations des nus propri�taires*/


/**************************************************************************************************************************************************************/
/*		e. Abattements sp�ciaux (passage du revenu net global au revenu net imposable)											 		                      */
/**************************************************************************************************************************************************************/

    %let abat_spe_age_plaf_1 = %sysfunc(round(14725*&evol_bareme.));  	/*P0580 1 plafond de l'abattement 1 pour personnes �g�es invalides*/
    %let abat_spe_age_plaf_2 = %sysfunc(round(23724*&evol_bareme.));  	/*P0600 2 plafond de l'abattement 2 pour personnes �g�es invalides*/
    %let abat_spe_age_mont_1 = %sysfunc(round(2346*&evol_bareme.));   	/*P0590 1 montant de l'abattement 1 pour personnes �g�es invalides*/
    %let abat_spe_age_mont_2 = %sysfunc(round(1173*&evol_bareme.));     /*P0610 2 montant de l'abattement 2 pour personnes �g�es invalides*/
    %let abat_spe_enf_marie = %sysfunc(round(5732*&evol_bareme.));      /*P0620 abattement pour enfants mari�s*/  

    /*D�c�te*/ 
    %let plaf_decote_celib = %sysfunc(round(1554*&evol_bareme.)) ;     	/*plafond d�c�te*/
    %let plaf_decote_couple = %sysfunc(round(2560*&evol_bareme.)) ;     
    %let pente_decote_celib = 0.75 ;
    %let pente_decote_couple = 0.75 ;


/**************************************************************************************************************************************************************/
/*		f. R�ductions d'impots (RI)																								 		                      */
/**************************************************************************************************************************************************************/

    /*RI pour dons effectu�s � des organismes d'aide aux personnes en difficult�*/ 
    %let dons_difficult_plaf = %sysfunc(round(527*&evol_bareme.));     	/*P0545 plafond pour dons aide aux personnes en difficult�*/
    %let dons_difficult_taux = 0.75 ;   /*taux de r�duction d'imp�t pour les dons � des organismes d'aide aux personnes en difficult�*/

	%let dons_utipub_plaf = 0.20 ;      /*plafond de r�duction d'imp�t pour les autres dons (association d'utilit� publique, organismes d'int�r�t g�n�ral, parti politique*/
    %let dons_utipub_taux = 0.66 ;      /*taux de r�duction d'imp�t pour les autres dons (association d'utilit� publique, organismes d'int�r�t g�n�ral, parti politique)*/

    /*RI Cotisations syndicales*/
    %let cot_syndic_plaf = 0.01 ;       /*plafond de r�duction d'imp�t pour les cotisations syndicales*/
    %let cot_syndic_taux = 0.66 ;       /*taux de r�duction d'imp�t pour les cotisations syndicales (proportionnel au salaire, pension, rente viag�re moins cotsoc*/

    /*RI Travaux de restauration immobili�re*/
    %let rest_immo_plaf  = 100000;      /*P0992 d�penses de restauration immobili�re en secteur sauvegard� ou assimil�*/
    %let rest_immo_taux1 = 0.22 ;       /*taux de r�duction 1 pour d�penses de restauration immobili�re en secteur sauvegard� ou assimil�*/
    %let rest_immo_taux2 = 0.30 ;       /*taux de r�duction 2 pour d�penses de restauration immobili�re en secteur sauvegard� ou assimil�*/
    %let rest_immo_taux3 = 0.30 ;
    %let rest_immo_taux4 = 0.40 ;
    %let rest_immo_taux5 = 0.27 ;

    /*RI D�pense de protection du patrimoine naturel*/
    %let protect_nat_plaf = 10000;      /*P0991 plafond de d�penses de protection du patrimoine naturel*/
    %let protect_nat_taux = 0.18 ;      /*taux de r�duction pour d�penses de protection du patrimoine naturel*/

    /*RI pour salari� � domicile*/ 
    %let sal_dom_plaf = 12000;          /*P0496a plafond des sommes vers�es pour emploi d'un salarie � domicile*/
    %let sal_dom_enf_charge_majo = 1500;/*P0496b majoration par enfant � charge ou rattach�, + 65 ans, APA (emploi d'un salarie � domicile)*/
    %let sal_dom_plaf_max = 15000;      /*P0496c plafond maximal (emploi d'un salari� � domicile), aussi indemnisation en cas de 1ere ann�e d'embauche*/
    %let sal_dom_1ere_emb_plaf = 18000; /*P0496d plafond port� � 18000� en cas de premi�re embauche du salari� � domicile*/
    %let sal_dom_inv_plaf = 20000;      /*P0497 plafond d'emploi � domicile si la personne est invalide*/
    %let sal_dom_taux = 0.50 ;          /*taux de r�duction d'imp�t pour un salari� � domicile*/

    /*RI pour int�r�ts au titre du diff�r� de paiement accord� aux agriculteurs*/ 
    %let diff_agri_seul_plaf = 5000;    /*P0491 plafond RI pour int�r�ts au titre du diff�r� de paiement accord� aux agriculteurs : c�libataires, etc. (CDV)*/
    %let diff_agri_couple_plaf = 10000; /*P0492 plafond RI pour int�r�ts au titre du diff�r� de paiement accord� aux agriculteurs : couples*/
    %let diff_agri_taux = 0.50 ;        /*taux de r�duction au titre du diff�r� de paiement accord� aux agriculteurs*/

    /*RI en cas de divorce*/ 
    %let prest_divorce_plaf = 30500;    /*P0493 plafond RI prestations compensatoires vers�es en cas de divorce*/
    %let divorce_taux = 0.25 ;         	/*taux de r�duction au titre de prestations compensatoires suite � un divorce*/

    /*RI Fonds commun de placement dans l�innovation*/
    %let fcpi_taux = 0.22 ;            	/*taux de r�duction pour un investissement dans un fond commun de placement dans l'innovation*/
    %let fcpi_couple_plaf = 24000;      /*P0295b  plafond FCPI couple*/
    %let fcpi_seul_plaf  = 12000;       /*P0296b plafond FCPI CDV*/

    /*RI Fonds d�investissement de proximit�*/
    %let fip_taux = 0.18 ;              /*taux de r�duction pour un investissement dans un fond d'investissement de proximit�*/
    %let fip_seul_plaf = 12000;         /*P0296c plafond FIP CDV*/
    %let fip_couple_plaf = 24000;    	/*P0295c plafond FIP Couple*/

    %let fip_corse_taux = 0.38 ;        /*taux de r�duction pour un investissement dans un fond d'investissement de proximit� (FIP) d�di� aux entreprises corses*/
    %let fip_seul_corse_plaf = 12000;   /*P0296d plafond FIP c�libataire etc. Corse*/
    %let fip_couple_corse_plaf  = 24000;/*P0295d Plafond FIP couple Corse*/

    %let fip_dom_taux = 0.42;
    %let fip_seul_dom_plaf     = 12000 ;
    %let fip_couple_dom_plaf = 24000 ;

    /*RI pour conservation et restauration d'objets class�s monuments historiques*/ 
    %let monu_hist_plaf = 20000;     	/*P0550 plafond cr�dit d imp�t conservation et restauration de monuments historiques*/
    %let monu_hist_taux = 0.18 ;        /*taux de r�duction pour d�penses de conservation et restauration de monuments historiques*/

    /*RI SOFICA*/  
    %let sofica_plaf = 18000;      		/*P0292 plafond SOFICA 25% du RI avec plafond a 18000*/
    %let sofica_plaf_taux = 0.25 ;      /*plafond de r�duction pour une souscription au capital SOFICA*/
    %let sofica_ded_taux1 = 0.30 ;      /*taux 1 de r�duction pour une souscription au capital SOFICA*/
    %let sofica_ded_taux2 = 0.36 ;      /*taux 2 de r�duction pour une souscription au capital SOFICA*/

    /*RI pour souscription au capital des PME*/
    %let cap_pme_couple_plaf_1 = 40000;	/*P0295 1 plafond capital des PME Couple*/
    %let cap_pme_seul_plaf_1   = 20000;	/*P0296 1 plafond capital des PME CDV*/
    %let cap_pme_couple_plaf_2 = 50000;	/*P0298 2 plafond capital des PME Couple*/
    %let cap_pme_seul_plaf_2 = 100000;	/*P0299 2 plafond capital des PME CDV*/
    %let cap_pme_taux1 = 0.18 ;         /*taux de r�duction pour une souscription au capital des PME*/
    %let cap_pme_taux2 = 0.22 ;         /*taux de r�duction pour une souscription au capital des PME*/
    %let cap_pme_taux3 = 0.25 ;

    /*RI pour int�r�ts d'emprunts pour reprise de soci�t�*/
    %let int_repr_couple_plaf = 40000; 	/*P0295e plafond int�r�ts reprise soci�t� Couple*/
    %let int_repr_seul_plaf = 20000;   	/*P0296e  plafond int�r�ts reprise soci�t� CDV*/
    %let reprise_soc_taux = 0.25 ;      /*taux de r�duction pour les interets d'emprunts pour reprise de soci�t�*/
    
    /*RI pour Investissements forestiers*/  
    %let foret_acq_taux = 0.18 ;        	/*taux de r�duction pour investissements forestiers*/
    %let foret_acq_seul_plaf     =  5700 ;	/*P0515a1 limite cotisations pour d�fense des for�ts contre l'incendie : Acquisition, personne seule*/
    %let foret_acq_couple_plaf   = 11400 ;	/*P0515a2 limite cotisations pour d�fense des for�ts contre l'incendie : Acquisition, CMP*/
    %let foret_trav_seul_plaf    =  6250 ;	/*P0515b1 limite cotisations pour d�fense des for�ts contre l'incendie : Travaux, personne seule*/
    %let foret_trav_couple_plaf  = 12500 ;	/*P0515b2 limite cotisations pour d�fense des for�ts contre l'incendie : Travaux, CMP*/
    %let foret_contr_seul_plaf   =  2000 ;	/*P0515c1 limite cotisations pour d�fense des for�ts contre l'incendie : Contrat, personne seule*/
    %let foret_contr_couple_plaf =  4000 ;	/*P0515c2 limite cotisations pour d�fense des for�ts contre l'incendie : Contrat, CMP*/
    %let foret_ass_seul_plaf =      6250 ;	/*limite cotisations pour d�fense des for�ts contre l'incendie : Assurance,personne seule*/  
    %let foret_ass_couple_plaf = 12500   ;	/*limite cotisations pour d�fense des for�ts contre l'incendie : Assurance, CMP*/  
    %let foret_ass_taux = 0.76;
    %let foret_rep_taux = 0.25 ;

    /*RI D�fense des f�ret contre l'incendie*/   
    %let foret_cot_plaf          =  1000 ;	/*P0515 limite cotisations pour d�fense des for�ts contre l'incendie*/
    %let foret_cot_taux = 0.50 ;       		/*taux de r�duction pour d�pense en defense des forets contre l'incendie*/

    /*RI pour d�penses d'accueil pour personnes �g�es d�pendantes*/
    %let age_long_sejour_plaf = 10000; 		/*P0498 plafond �tablissement long sejour*/
    %let age_long_sejour_taux = 0.25 ;  	/*taux de r�duction pour d�penses d'accueil pour personnes �g�es d�pendantes*/

    /*RI Rentes survie, contrat d'�pargne handicap*/
    %let rente_survie_plaf = 1525;     		/*P0510 limite de r�duction d'imp�t rente survie*/
    %let rente_survie_enf_charge_majo = 300;/*P0511 majoration de r�duction d'imp�t rente survie par enfant � charge*/
    %let rente_survie_taux = 0.25 ;     	/*taux de r�duction pour rente survie, contrat d'�pargne handicap*/

    /*RI pour investissements locatifs dans le secteur touristique*/
       	/*Logements acquis ou achev�s avant le 01/01/2001*/
    %let inv_loc_01_seul_plaf = 38120;  	/*P0504a limite Investissement locatif touristique dans les zones rurales pers. seule*/
    %let inv_loc_01_couple_plaf = 76240;	/*P0504b limite Investissement locatif touristique dans les zones rurales couple*/

      	/* Logements acquis ou achev�s � compter du 01/01/2001 au 31/12/2003*/
    %let inv_loc_0103_seul_plaf  = 45760; 	/*P0504c limite Investissement locatif touristique dans les zones rurales pers. seule*/
    %let inv_loc_0103_couple_plaf = 91520;	/*P0504d limite Investissement locatif touristique dans les zones rurales couple*/

   		/* 1/ Logements acquis ou achev�s � compter du 01/01/2004 OU
           2/ Logements acquis ou achev�s entre le 01/01/2005 et le 31/12/2010 
           3/ Acquisition � compter du 01/01/2004 faisant l objet de travaux achev�s entre le 01/01/2004 et le 31/12/2010
           4/ Travaux de reconstruction, etc. pay�s entre le 01/01/2005 et le 31/12/2010*/

    %let inv_loc_04_seul_plaf = 50000;   	/*limite Investissement locatif touristique dans les zones rurales pers. seule*/
    %let inv_loc_04_couple_plaf = 100000;  	/*limite Investissement locatif touristique dans les zones rurales couple*/


    %let inv_loc_taux1 = 0.25 ;         	/*taux de r�duction 1 pour investissement locatif dans le secteur touristique*/
    %let inv_loc_taux2 = 0.20 ;         	/*taux de r�duction 2 pour investissement locatif dans le secteur touristique*/
    %let inv_loc_trav_taux1 = 0.15 ;    	/*taux de r�duction 1 relatif � des travaux*/
    %let inv_loc_trav_taux2 = 0.20 ;    	/*taux de r�duction 2 relatif � des travaux*/
    %let inv_loc_trav_taux3 = 0.30 ;    	/*taux de r�duction 3 relatif � des travaux*/
    %let inv_loc_trav_taux4 = 0.40 ;    	/*taux de r�duction 4 relatif � des travaux*/

    /*RI pour investissement en Outre-mer*/ 
    %let inv_dom_plaf = 40000;         		/*P0990 plafond investissement dans les DOM*/

    /*RI pour frais de comptabilit� et d'adh�sion � un CGA*/ 
    %let cga_frais_adh_plaf = 915;          /*P0915 maximum pour frais de comptabilit� pour l'adh�sion � un CGA*/

    /*RI pour aide aux cr�ateurs d'entreprise*/
    %let aide_creat_reduc = 1000;        	/*P0516 RI aide cr�ateurs d'entreprise*/
    %let aide_creat_majo_handi = 400;     	/*P0517 majoration RI aide aux cr�ateurs d'entreprise pour personne handicap�e*/

    /*RI pour frais de scolarisation*/  
    %let college_reduc = 61;               	/*P0440 dans un coll�ge*/
    %let lycee_reduc = 153;              	/*P0441 dans un lyc�e*/
    %let etab_sup_reduc = 183;              /*P0442 dans un �tablissement d'enseignement sup�rieur*/

    /*RI Investissement Duflot*/ 
    %let duflot_plaf_dec = 300000 ; 
    %let duflot_taux1 = 0.29 ; 
    %let duflot_taux2 = 0.18 ; 

    /*RI Investissement Scellier*/
    %let scl_plaf_dec = 300000;

    %let scl_met_bbc_taux1 = 0.13 ;    /*taux de reduction pour un investissement locatif loi Scellier r�alis� � compter du 01.01.2011 en m�tropole logement BBC*/
    %let scl_met_bbc_taux2 = 0.22 ;    /*taux de reduction pour un investissement locatif loi Scellier r�alis� � compter du 01.01.2011 en m�tropole logement BBC*/
    %let scl_met_bbc_taux3 = 0.25 ;    /*taux de reduction pour un investissement locatif loi Scellier r�alis� ou engag� avant le 01.01.2011 en m�tropole logement BBC*/

    %let scl_met_nonbbc_taux1 = 0.06 ; /*taux de reduction pour un investissement locatif loi Scellier r�alis� � compter du 01.01.2011 en m�tropole logement non BBC*/
    %let scl_met_nonbbc_taux2 = 0.15 ; /*taux de reduction pour un investissement locatif loi Scellier r�alis� avant le 01.01.2011 en m�tropole logement non BBC*/

    %let scl_OM_taux1 = 0.24;          /*taux de reduction pour un investissement locatif loi Scellier r�alis� � compter du 01.01.2011 en outre mer*/
    %let scl_OM_taux2 = 0.36 ;         /*taux de reduction pour un investissement locatif loi Scellier r�alis� avant le 01.01.2011 en outre mer*/
    %let scl_OM_taux3 = 0.40 ;         /*taux de reduction pour un investissement locatif loi Scellier r�alis� avant le 01.01.2011 en outre mer*/

    /*RI Location meubl�e non professionnelle*/
    %let InvMeuNonPro_taux1 = 0.11  ;   /*taux de r�duction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_taux2 = 0.18  ;   /*taux de r�duction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_taux3 = 0.20  ; 	/*taux de r�duction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_taux4 = 0.25  ; 	/*taux de r�duction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_plaf = 300000 ;   /*plafond de montant des cases ouvrant le droit � une r�duction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/

    /*RI investissement outre-mer*/
    %let OM_plaf = 40000 ;              /*plafonnement de reduction pour investissements locatifs dans les DOM*/
    %let OM_plaf2 = 36000 ;
    %let OM_plaf3 = 30600 ;

    %let OM_plaf_specif1 = 40000 ;      /*plafonnement sp�cifique 1 de reduction pour investissements locatifs dans les DOM*/
    %let OM_plaf_specif2 = 60000 ;      /*plafonnement sp�cifique 2 de reduction pour investissements locatifs dans les DOM*/
    %let OM_plaf_specif3 = 74286 ;      /*plafonnement sp�cifique 3 de reduction pour investissements locatifs dans les DOM*/

    %let OM_taux1 = 0.35 ;  
    %let OM_taux2 = 0.375 ;  
    %let OM_taux3 = 0.40 ;
    %let OM_taux4 = 0.4737 ;
    %let OM_taux5 = 0.50 ;
    %let OM_taux6 = 0.60 ;
    %let OM_taux7 = 0.65 ;

    %let OM_lim1 = 0.15 ;               /*limite pour les investissements dans logement social et r�alis�s ou engag�s avant 2011*/ 
    %let OM_lim2 = 0.13 ;               /*limite pour les investissements r�alis�s ou engag�s en 2011*/
    %let OM_lim3 = 0.11 ;               /*limite pour les investissements r�alis�s ou engag�s apr�s 2012*/

    /*RI pour motifs environnementaux*/ 
    %let qualenv_plaf = 8000 ; 

    %let prev_risque_seul_plaf = 5000; 		/*P0994 plafond c�libataire travaux de pr�vention des risques technologiques dans les logements donn�s en location*/
    %let prev_risque_couple_plaf = 10000;   /*P0995 plafond couple M/P travaux de pr�vention des risques technologiques dans les logements donn�s en location*/
    %let prev_risque_pac_majo = 400;        /*P0996 majoration du plafond pour personnes � charge (PAC) travaux de pr�vention des risques technologiques dans les logements donn�s en location*/
    
     %let prev_risque_taux = 0.40 ;      	/*taux de r�duction*/    

    /*RI du PLF 2017*/
    %let switch_redIR=0;
    %let seuil_redIR_1 = 18500;
    %let seuil_redIR_2=20500;
    %let seuil_redIR_dp = 3700;
    %let taux_redIR = 0.2;


/**************************************************************************************************************************************************************/
/*		g. Cr�dits d'impots (CI)																							 		                          */
/**************************************************************************************************************************************************************/

    /*CI sur les dividendes*/ 
	/*Suppression pour les revenus � partir de 2010*/
    %let div_50_seul_plaf = 115;      /*P0494  cr�dit d'imp�t dividendes 50% plafond : seuls*/
    %let div_50_couple_plaf = 230;    /*P0494 cr�dit d'imp�t dividendes 50% plafond : couples*/  

    /*CI d�veloppement durable / d�penses de gros �quipement*/ 
    %let gros_equip_seul_plaf = 8000; 	/*P0505 plafond d�pense de gros �quipement*/
    %let gros_equip_couple_plaf = 16000;/*P0506 plafond d�pense de gros �quipement : le fait d'�tre en couple ne d�double plus l'avantage*/
    %let gros_equip_majo = 400;   		/*P0507 majoration Plafond d�pense de gros �quipement*/

    /*CI int�r�ts pr�t �tudiant*/ 
    %let int_pret_etud_plaf = 1000;   	/*P0508 plafond Int�r�ts pr�ts �tudiants*/

    /*CI pour Cr�dit d imp�t inter�t d'emprunt*/ 
    %let int_empr_seul_plaf = 3750;    	/*P0518 limite inter�t d'emprunt personne seule*/
    %let int_empr_charge_majo = 500;   	/*majoration inter�t d'emprunt personne � charge*/

    /*CI pour frais de garde des jeunes enfants*/
    %let garde_enf_plaf = 2300;    		/*P0480 plafond frais de garde par enfant*/
    %let garde_enf_alt_plaf = 1150;   	/*P0481 plafond frais de garde par enfant en r�sidence altern�e*/


/**************************************************************************************************************************************************************/
/*		h. Droits																												 		                      */
/**************************************************************************************************************************************************************/

    /*Seuils de recouvrement et de restitution*/ 
    %let seuil_perc_avt_restit = 61; 	/*P0960 minimum perception (cf art. 1657-1 bis et 2)*/
    %let seuil_perc_apt_restit = 12; 	/*P0970 minimum de perception apr�s restitutions (cf art. 1657-1 bis et 2)*/
    %let seuil_restit = 8;           	/*P0980 minimum de restitution (cf art. 1965 L)*/

    /*Age*/
    %let age_seuil = 65 ;               /*seuil � partir duquel on est consid�r� comme �g�*/

    /*PV mobili�res*/
    %let taux_bspce_1 = 0.19;           /*taux d'imposition des plus-values sur bons de souscription de parts de cr�ateurs d'entreprises (CGI 163 bis G)*/
    %let taux_bspce_2 = 0.30 ;          /*taux d'imposition des plus-values sur bons de souscription de parts de cr�ateurs d'entreprises (si moins de trois ans d'exercice dans la soci�t�) (CGI 163 bis G)*/

    %let pv_mob_taux = 0.24 ;           /*taux d'imposition des plus-values � taux proportionnel*/
    %let pv_mob_taux_entr = 0.19 ;      /*taux d'imposition des plus-values � taux proportionnel*/
    %let pv_pro_taux = 0.16 ;           /*taux d'imposition des plus-values professionnelles � taux proportionnel*/
    %let pv_dom_taux1 = 0.10 ;          /*taux d'imposition des gains de cession de droits sociaux au dela du seuil de 25830 � en Guyane*/
    %let pv_dom_taux2 = 0.12 ;          /*taux d'imposition des gains de cession de droits sociaux au dela du seuil de 25830 � dans les autres DOM*/

    %let pv_pea_taux_1 = 0.19 ;         /*taxation suite � une cloture de PEA entre la 2�me et la 5�me ann�e*/
    %let pv_pea_taux_2 = 0.225 ;        /*taxation suite � une cloture de PEA avant expiration de la deuxi�me ann�e*/

    %let taux_aga_1 = 0.025;
    %let taux_aga_2 = 0.08 ;
    %let taux_aga_3 = 0.1 ;

    %let pv_titre_taux1 = 0.18 ;        /*gains de lev�e d'options sur titres taxables � 18%*/
    %let pv_titre_taux2 = 0.30 ;        /*gains de lev�e d'options sur titres taxables � 30%*/
    %let pv_titre_taux3 = 0.40 ;        /*gains de lev�e d'options sur titres taxables � 40%*/
    %let pv_etrangeres_taux1 = 0.16 ;   /*taux de r�duction*/
    %let pv_etrangeres_taux2 = 0.18 ;   /*taux de r�duction*/

    /*Prel�vements forfaitaires lib�ratoires*/
    %let pfl_avi = 0.075 ; 				/*sur les produits d'assurances-vie*/
    %let pfl_int    = 0 ;
    %let pfl_div    = 0 ;

	/*R�ductions d imp�t*/
    %let sofipeche_ded_taux = 0.36 ;   
    %let env_plaf = 8000;               /*P0993 plafond d�penses en faveur de la qualit� environnementale des logements donn�s en location*/    
    %let bien_cult_taux = 0.40 ;        /*taux de r�duction*/

    %let ci_qualenvir_taux1 = 0.13 ;  	/*cr�dit d'impot pour d�penses en faveur de la qualit� environnementale*/
    %let ci_qualenvir_taux2 = 0.22 ;   	/*cr�dit d'impot pour d�penses en faveur de la qualit� environnementale*/
    %let ci_qualenvir_taux3 = 0.36 ;    /*cr�dit d'impot pour d�penses en faveur de la qualit� environnementale*/
    %let ci_qualenvir_taux4 = 0.45 ;   	/*cr�dit d'impot pour d�penses en faveur de la qualit� environnementale*/
    %let ci_qualenvir_taux5 = 0.50 ;    /*cr�dit d'impot pour d�penses en faveur de la qualit� environnementale photovoltaique*/
  
    %let ci_aidepers_hab_taux1 = 0.15 ; /*taux de r�duction*/
    %let ci_aidepers_hab_taux2 = 0.25 ; /*taux de r�duction*/
    %let ci_aidepers_hab_taux3 = 0.30 ; /*taux de r�duction*/

    %let droit_bail_taux = 0.25 ;       /*taux de r�duction*/
    %let garde_enf_taux = 0.50 ;        /*taux de r�duction*/
    %let int_pret_etud_taux = 0.25 ;    /*taux de r�duction*/
    %let int_empr_taux1 = 0.20 ;        /*taux de r�duction*/
    %let int_empr_taux2 = 0.30 ;        /*taux de r�duction*/
    %let int_empr_taux3 = 0.40 ;        /*taux de r�duction*/
    %let int_empr_taux4 = 0.15 ;
    %let int_empr_taux5 = 0.25 ;
    %let int_empr_taux6 = 0.10 ;

    %let assur_loy_imp_taux = 0.38 ;    /*taux de r�duction*/


    /*Imp�t forfaitaire sur les int�r�ts*/
    %let taux_impot_forf = 0.24 ;
    
    /*Abattement pour r�sidence dans les DOM */
    %let abat_dom_taux1 = 0.30 ; 		/*taux d'abattement pour les r�sidents en Guadeloupe, Martique, R�union*/
    %let abat_dom_plaf1 = 5100 ; 		/*plafond d'abattement pour les r�sidents en Guadeloupe, Martique, R�union*/

    %let abat_dom_taux2 = 0.40 ; 		/*taux d'abattement pour les r�sidents en Guyane*/
    %let abat_dom_plaf2 = 6700 ; 		/*plafond d'abattement pour les r�sidents en Guyane*/

    /*Plafonnement des niches fiscales*/
    %let niche_plaf_fixe = 10000;
    %let niche_plaf_majo = 8000 ;
    %let niche_plaf_taux = 0 ;

    /*PPE*/ /*supprim�e en 2016*/ 
    %let ppe_foyer1      =   16251 ;
    %let ppe_foyer2      =   32498 ;
    %let ppe_foyer3      =   4490  ;

    %let ppe_indiv1      =   3743  ;
    %let ppe_indiv2      =   12475 ;
    %let ppe_indiv3      =   17451 ;
    %let ppe_indiv4      =   24950 ;
    %let ppe_indiv5      =   26572 ;

    %let ppe_mono        =   83    ;
    %let ppe_isoleENF    =   72    ;
    %let ppe_coupleENF   =   36    ;
    %let ppe_seuil       =   30    ;

    %let ppe_partiel     =   0.85  ;

    %let ppe_taux1       =   0.077 ;
    %let ppe_taux2       =   0.193 ;
    %let ppe_taux3       =   0.051 ;

    /*Contribution exceptionnelle sur les hauts revenus (CEHR)*/
    %let CEHR_taux1 = 0.03 ;
    %let CEHR_taux2 = 0.04 ;
    %let CEHR_seuil1 = 250000 ;
    %let CEHR_seuil2 = 500000 ;

    /*Pr�l�vement lib�ratoire sur pensions de retraites vers�es sous forme de capital*/
    %let pfl_pens_taux = 0.075 ;
    %let pfl_pens_abat = 0.1 ;
    %let tx_cidd_unique = 0.30 ;

	/*Mise en place du taux unique � 30% sur le CITE, de fa�on r�troactive pour les d�penses engag�es � partir du 1er septembre 2014*/   
    %let cidd_tx_1 = &tx_cidd_unique.; /*0.10*/
    %let cidd_tx_2 = &tx_cidd_unique.; /*0.11*/
    %let cidd_tx_3 = &tx_cidd_unique.; /*0.15*/
    %let cidd_tx_4 = &tx_cidd_unique.; /*0.17*/
    %let cidd_tx_5 = &tx_cidd_unique.; /*0.26*/
    %let cidd_tx_6 = &tx_cidd_unique.; /*0.32*/

    %let cidd_tx_1_b = &tx_cidd_unique.; /*0.18*/
    %let cidd_tx_3_b = &tx_cidd_unique.; /*0.23*/
    %let cidd_tx_4_b = &tx_cidd_unique.; /*0.26*/
    %let cidd_tx_5_b = &tx_cidd_unique.; /*0.34*/
    %let cidd_tx_6_b = &tx_cidd_unique.; /*0.40*/

    %let plafond_cidd = 8000 ;
    %let majo_cidd = 400 ;

    %let seuil_rfr_cidd = 0 ;
    %let tx_cidd_bouquet =  0;
    %let tx_cidd_seul = 0 ;
 


    %let pv_abat_exp = 0.61 ;
    %let switch_pvm = 1 ;

    /*Param�tres � mettre � 0 lors du calcul des �lasticit� (pour avoir l'IR hors CI suivis en d�pense)*/
    %let switch_calc_elast = 1 ;
    %let switch_pfo = 0 ;



%mend Parametres ;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       									III. L�gislation 2016 sur les revenus 2015	                 									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%let evol_bareme=1; %Parametres(&evol_bareme.);


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est r�gi par la licence CeCILL V2.1 soumise au droit fran�ais et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les param�tres de la l�gislation socio-fiscale figurant dans les programmes 6, 7a et 7b sont r�gis par la � Licence Ouverte / Open License � Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/
