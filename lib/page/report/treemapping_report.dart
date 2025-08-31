import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'treemapping_detail.dart';
import '../../constants/colors.dart';
import '../../models/data_pohon.dart';
import '../../services/data_pohon_service.dart';

class TreeMappingReportPage extends StatelessWidget {
  final DataPohonService _dataPohonService = DataPohonService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealGelap,
        title: Text(
          'Laporan Peta Pohon',
          style: TextStyle(
            color: AppColors.yellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<DataPohon>>(
        stream: _dataPohonService.getAllDataPohon(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data pohon tersedia'));
          }

          final pohonList = snapshot.data!;
          return ListView.builder(
            itemCount: pohonList.length,
            itemBuilder: (context, index) {
              final pohon = pohonList[index];
              return Column(
                children: [
                  ListTile(
                    leading: pohon.fotoPohon.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: pohon.fotoPohon,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/logo/logo.png',
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.asset(
                            'assets/logo/logo.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                    title: Text(
                      'Pohon ID #${pohon.idPohon}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    subtitle: Text(
                      'Lokasi: ${pohon.up3}, ${pohon.ulp}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TreeMappingDetailPage(pohon: pohon),
                        ),
                      );
                    },
                  ),
                  if (index < pohonList.length - 1)
                    Divider(color: AppColors.cyan, thickness: 1),
                ],
              );
            },
          );
        },
      ),
    );
  }
}