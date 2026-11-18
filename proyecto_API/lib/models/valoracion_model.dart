class ValoracionModel {
  final double promedio;
  final int total;
  final int? miPuntuacion;

  ValoracionModel({
    required this.promedio,
    required this.total,
    this.miPuntuacion,
  });

  factory ValoracionModel.fromJson(Map<String, dynamic> json) {
    return ValoracionModel(
      promedio: (json['promedio'] as num).toDouble(),
      total: json['total'] as int,
      miPuntuacion: json['mi_puntuacion'] as int?,
    );
  }
}
