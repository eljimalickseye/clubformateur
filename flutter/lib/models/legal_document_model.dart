import 'package:cloud_firestore/cloud_firestore.dart';

class LegalDocumentModel {
  final String id;
  final String type;
  final String title;
  final String content;
  final String version;
  final DateTime effectiveDate;

  LegalDocumentModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.version,
    required this.effectiveDate,
  });

  factory LegalDocumentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return LegalDocumentModel(
      id: doc.id,
      type: d['type'] ?? 'reglement',
      title: d['title'] ?? 'Document legal',
      content: d['content'] ?? '',
      version: d['version'] ?? '1.0',
      effectiveDate: d['effectiveDate'] is Timestamp
          ? (d['effectiveDate'] as Timestamp).toDate()
          : DateTime(2025, 1, 1),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'title': title,
        'content': content,
        'version': version,
        'effectiveDate': effectiveDate,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static LegalDocumentModel get defaultReglement => LegalDocumentModel(
        id: 'reglement_interieur',
        type: 'reglement',
        title: 'Règlement Intérieur & Charte Déontologique',
        version: '1.2',
        effectiveDate: DateTime(2025, 2, 1),
        content: """# Règlement Intérieur & Charte Déontologique -- Club des Formateurs

Version 1.2 - Mise à jour et effective au 1er Février 2025

---

## Article 1 -- Objet et Champ d'Application

Le présent règlement intérieur régit le fonctionnement, les droits, devoirs et engagements de tous les membres de la plateforme Club des Formateurs : apprenants, formateurs certifiés, correcteurs pédagogiques et administrateurs.

## Article 2 -- Inscription, Comptes et Accès

2.1 L'accès aux formations et aux services interactifs implique l'acceptation sans réserve de ce règlement et des conditions générales.

2.2 Chaque compte est strictement personnel, nominatif et confidentiel. Le partage d'identifiants ou d'accès est formellement interdit sous peine de radiation immédiate sans remboursement.

2.3 Les accès aux formations payantes sont activés instantanément dès validation du paiement via Wave SN, Orange Money SN ou Carte Bancaire.

## Article 3 -- Engagements & Droits des Apprenants

3.1 Les apprenants s'engagent à participer avec assiduité et respect aux cours, ateliers et sessions live.

3.2 La messagerie permet aux apprenants d'échanger avec leur correcteur attitré et leur formateur via des messages écrits et des messages vocaux pour poser des questions précises sur les exercices.

3.3 Les devoirs et exercices doivent être le résultat d'un travail personnel. Tout plagiat avéré ou soumission frauduleuse entraîne l'annulation de la note et l'avertissement formel.

3.4 Les apprenants bénéficient de la Garantie Légale Satisfait ou Remboursé de 14 jours, sous réserve du respect des critères de l'Article 8.

## Article 4 -- Statut, Obligations & Rémunération des Formateurs

4.1 **Agrément & Validation** : Tout formateur doit soumettre son profil et faire valider son identité par l'administration avant de pouvoir publier des cours.

4.2 **Visibilité sur la plateforme** : Conformément à la politique d'excellence du Club, un formateur n'est publiquement visible sur la page d'accueil et le carrousel que s'il a créé et publié au minimum une (1) formation complète validée, accompagnée obligatoirement de sa vidéo de présentation personnelle.

4.3 **Sessions Live** : Les sessions en direct durent 1h30 (90 minutes) :
- 60 minutes dédiées à la théorie approfondie, démonstrations concrètes et interactions ;
- 30 minutes dédiées aux exercices pratiques guidés et aux questions des participants.

4.4 **Suivi Pédagogique & Correcteurs** : Le formateur collabore étroitement avec le correcteur pédagogique qui lui est assigné par l'administration pour harmoniser le barème d'évaluation des devoirs.

4.5 **Messagerie & Retours** : Le formateur dispose d'un accès complet à la messagerie textuelle et vocale pour guider les élèves de ses promotions.

4.6 **Rémunération & Retraits** :
- Le formateur perçoit 90% du montant net de chaque vente de formation générée.
- La plateforme retient une commission de 10% pour l'hébergement haut débit, la bande passante vidéo LiveKit, le support et la passerelle de paiement.
- Les retraits sont automatisés et exécutés sous 24 à 48 heures via Wave SN ou Orange Money SN dès que le solde disponible atteint 10 000 FCFA.

## Article 5 -- Mission & Obligations des Correcteurs

5.1 Les correcteurs sont accrédités et assignés par le Super Administrateur auprès d'un formateur référent.

5.2 Le correcteur a pour mission exclusive de corriger avec rigueur et bienveillance l'ensemble des devoirs et travaux pratiques rendus par les apprenants.

5.3 Délai de correction : Toute copie rendue doit être corrigée dans un délai maximum de 72 heures ouvrées, accompagnée d'une note sur 20, d'un corrigé détaillé et d'un commentaire audio ou écrit individualisé.

5.4 Les sessions live animées par le correcteur sont d'une durée de 1h30 et sont 100% consacrées à la résolution d'exercices et au déblocage pratique des élèves.

## Article 6 -- Propriété Intellectuelle & Droits d'Auteur

6.1 Les cours, vidéos, supports, slides et projets fournis sont protégés par le droit de la propriété intellectuelle.

6.2 Tout téléchargement illégal, enregistrement d'écran ou rediffusion publique non autorisée fera l'objet de poursuites judiciaires immédiates.

## Article 7 -- Sanctions et Modération

Tout manquement délibéré aux règles énoncées ci-dessus expose son auteur à :
1. Un rappel à l'ordre écrit ;
2. La suspension temporaire des droits d'accès et de publication ;
3. L'exclusion définitive de la plateforme sans indemnité.

---

*Club des Formateurs - Apprendre, Enseigner, Évoluer*""",
      );

  static LegalDocumentModel get defaultRemboursement => LegalDocumentModel(
        id: 'garantie_remboursement',
        type: 'remboursement',
        title: 'Politique de Remboursement & Garantie Satisfait ou Remboursé',
        version: '1.0',
        effectiveDate: DateTime(2025, 2, 1),
        content: """# Garantie Satisfait ou Remboursé -- Club des Formateurs

Chez Club des Formateurs, notre priorité absolue est la qualité irréprochable des cours et la satisfaction tangible de nos apprenants. Nous offrons une garantie "Satisfait ou Remboursé" claire et transparente.

---

## 1. Délai de Rétractation et Garantie

Vous disposez d'un délai légal et contractuel de **14 jours calendaires** à compter de la date et heure d'achat de votre formation pour solliciter un remboursement intégral, sans pénalité.

## 2. Conditions d'Éligibilité au Remboursement

Pour être éligible au remboursement intégral à 100%, votre demande doit respecter les critères suivants :
- Avoir formulé la demande dans le délai de 14 jours ;
- Ne pas avoir visionné ou complété plus de **20%** du contenu vidéo de la formation ;
- Ne pas avoir téléchargé l'intégralité des ressources et codes sources exclusifs du formateur ;
- Ne pas avoir reçu de certificat de fin de formation ou d'attestation de réussite pour ce cours ;
- Ne pas avoir fait corriger de devoirs officiels par le correcteur attitré.

## 3. Prise en Charge & Modalités de Paiement

- Le remboursement est pris en charge à 100% par la plateforme Club des Formateurs.
- Le montant intégral payé est restitué sans frais administratifs sur le moyen de paiement utilisé lors de la commande (compte Wave, portefeuille Orange Money ou Carte Bancaire).
- Délais bancaires : Le virement de remboursement est déclenché sous 48 heures ouvrées après validation par l'équipe administrative.

## 4. Protection & Traitement du Formateur

Afin de protéger les intérêts de nos formateurs certifiés contre les abus, les revenus des ventes de cours sont conservés sous séquestre sécurisé pendant la période de garantie de 14 jours.
- En cas de demande de remboursement approuvée, la vente est annulée et aucun montant n'est imputé négativement au formateur au-delà de l'annulation de la commission concernée.
- Dès que l'élève dépasse 20% de progression ou que le délai de 14 jours expire, la part du formateur (90%) lui est immédiatement et définitivement acquise.

## 5. Comment Demander un Remboursement ?

La démarche est simple et rapide :
1. Rendez-vous dans votre Espace Apprenant -> **Mes Formations** ;
2. Sur la formation concernée, cliquez sur les options et sélectionnez **"Demander un remboursement"** ;
3. Vous pouvez également envoyer un message direct avec votre numéro de transaction à l'adresse support : `contact@clubformateurs.sn` ou via notre messagerie intégrée.

---

*L'équipe du Club des Formateurs s'engage pour votre réussite.*""",
      );

  static LegalDocumentModel get defaultContrat => LegalDocumentModel(
        id: 'contrat_utilisation',
        type: 'contrat',
        title: "Conditions Générales & Contrat d'Utilisation",
        version: '1.1',
        effectiveDate: DateTime(2025, 2, 1),
        content: """# Conditions Générales & Contrat d'Utilisation -- Club des Formateurs

Version 1.1 - Effective au 1er Février 2025

---

## Préambule

Le présent Contrat d'Utilisation est conclu entre Club des Formateurs et tout utilisateur s'inscrivant sur la plateforme. En vous inscrivant, vous reconnaissez avoir lu, compris et accepté l'intégralité des termes du présent Contrat.

## Article 1 -- Objet du Contrat

Le présent Contrat définit les conditions d'accès et d'utilisation des services proposés, notamment :
- L'accès aux formations professionnelles en ligne (vidéos HD, documents PDF, exercices interactifs)
- La participation aux sessions lives interactives théoriques et pratiques
- L'utilisation du système de messagerie écrite et vocale sécurisée
- L'accès aux services de correction individualisée de devoirs par des correcteurs accrédités
- La délivrance de certificats d'aptitude et de complétion vérifiables par QR Code

## Article 2 -- Compte Utilisateur et Sécurité

2.1 L'Utilisateur doit fournir des informations exactes, complètes et à jour lors de son inscription.

2.2 L'Utilisateur est seul responsable de la sécurité et de la confidentialité de ses identifiants.

2.3 Chaque personne physique ne peut posséder qu'un seul compte actif sur la plateforme.

## Article 3 -- Conditions Financières & Garantie

3.1 Les prix des formations sont affichés en francs CFA (FCFA) toutes taxes comprises.

3.2 Moyens de paiement acceptés : Wave Sénégal, Orange Money Sénégal, Cartes Bancaires (Visa/Mastercard).

3.3 Politique de Garantie : Chaque formation bénéficie d'une garantie légale de satisfaction de 14 jours conformément à notre Politique de Remboursement officielle.

## Article 4 -- Droits et Licences

4.1 En accédant à une formation, l'Utilisateur bénéficie d'une licence personnelle, non exclusive et non transférable pour consulter les contenus pédagogiques pour son apprentissage propre.

4.2 Cette licence n'autorise pas la reproduction, la diffusion commerciale ou la revente des contenus sous quelque forme que ce soit.

## Article 5 -- Données Personnelles et Respect de la Vie Privée

5.1 La Plateforme collecte et traite les données personnelles conformément aux lois en vigueur au Sénégal et dans l'espace CEDEAO (Loi relative à la protection des données à caractère personnel).

5.2 Les données collectées ne sont en aucun cas vendues, cédées ou louées à des tiers.

## Article 6 -- Responsabilités & Disponibilité

6.1 Club des Formateurs s'engage à mettre en œuvre une disponibilité maximale de la plateforme avec un objectif de taux de service de 99.8%.

6.2 En cas d'interruption temporaire pour maintenance, les utilisateurs sont prévenus préalablement par notification.

## Article 7 -- Résiliation

7.1 L'Utilisateur peut demander la suppression de son compte et de ses données à tout moment depuis les paramètres de son profil.

7.2 La Plateforme se réserve le droit de suspendre ou résilier sans préavis tout compte en cas de fraude avérée, piratage ou non-respect caractérisé du règlement.

## Article 8 -- Droit Applicable et Juridiction Compétente

Le présent Contrat est régi par la loi sénégalaise. Tout différend relatif à la validité, l'interprétation ou l'exécution du contrat sera soumis, à défaut de résolution amiable, aux tribunaux compétents de Dakar, Sénégal.

---

*Club des Formateurs - Apprendre, Enseigner, Évoluer*""",
      );
}
