class UnbordingContent {
  String image;
  String title;
  String description;

  UnbordingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}

List<UnbordingContent> contents = [
  UnbordingContent(
      title: 'Remplir des formulaires de demande de logement.!',
      image: 'lib/assets/icons/me/service.gif',
      description:
          "Permettez aux utilisateurs de remplir et soumettre facilement des demandes de logement en ligne et de suivre l'état de leur demande en temps réel."),
  UnbordingContent(
      title: 'Signaler des problèmes de maintenance dans les propriétés appartenant au ministère.',
      image: 'lib/assets/icons/me/admin1.gif',
      description:
          "Les utilisateurs peuvent signaler facilement des problèmes de maintenance dans les propriétés du ministère et suivre l'avancement des réparations."),
  UnbordingContent(
      title: 'Demander des informations ',
      image: 'lib/assets/icons/me/admin4.gif',
      description:
          "Demander des informations sur les procédures et conditions d'accès aux services du ministère."),
  UnbordingContent(
      title: 'Prendre des rendez-vous',
      image: 'lib/assets/icons/me/admin1.gif',
      description:
          "Permettez aux utilisateurs de réserver des rendez-vous en ligne pour rencontrer des responsables du ministère à des dates et heures convenables."),
  
];
