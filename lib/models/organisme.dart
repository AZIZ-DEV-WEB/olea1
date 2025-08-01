class OrganismeFormation {
  final String id;
  final String nom;
  final String address;
  final String contact;
  final String type;
  final bool active;

  OrganismeFormation({
    required this.id,
    required this.nom,
    required this.address,
    required this.contact,
    required this.type,
    required this.active,
  });

  // Convertir depuis Firestore
  factory OrganismeFormation.fromMap(Map<String, dynamic> data, String documentId) {
    return OrganismeFormation(
      id: documentId,
      nom: data['nom'] ?? '',
      address: data['address'] ?? '',
      contact: data['contact'] ?? '',
      type: data['type'] ?? '',
      active: data['active'] ?? false,
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'address': address,
      'contact': contact,
      'type': type,
      'active': active,
    };
  }
}
