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
    title: 'Évaluer les progrès des élèves',
    image: 'lib/assets/icons/me/progress.gif',
    description: "Suivez facilement les performances et l'évolution de chaque élève au fil du temps."),
  UnbordingContent(
    title: 'Créer des fiches d’évaluation personnalisées',
    image: 'lib/assets/icons/me/assessment.gif',
    description: "Permettez aux enseignants de créer des évaluations adaptées aux besoins de chaque élève."),
  UnbordingContent(
    title: 'Suivi des résultats et des progrès',
    image: 'lib/assets/icons/me/results.gif',
    description: "Affichez les résultats des évaluations et suivez les progrès des élèves dans différentes matières."),
  UnbordingContent(
    title: 'Partager des rapports avec les parents',
    image: 'lib/assets/icons/me/share_report.gif',
    description: "Générez des rapports détaillés et partagez-les facilement avec les parents des élèves."),
  UnbordingContent(
    title: 'Notifier les enseignants et parents',
    image: 'lib/assets/icons/me/notification.gif',
    description: "Recevez des rappels pour les évaluations et les progrès des élèves, et informez les parents."),
];

