import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class MoveCarRequestScreen extends StatefulWidget {
  final String? photoUrl;
  final String? requestId;
  final String? latitude;
  final String? longitude;

  const MoveCarRequestScreen({
    Key? key,
    this.photoUrl,
    this.requestId,
    this.latitude,
    this.longitude,
  }) : super(key: key);

  @override
  State<MoveCarRequestScreen> createState() => _MoveCarRequestScreenState();
}

class _MoveCarRequestScreenState extends State<MoveCarRequestScreen> {
  bool _isReporting = false;

  Future<void> _reportFake() async {
    if (widget.requestId == null) return;
    
    setState(() {
      _isReporting = true;
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('reportFakeRequest');
      await callable.call(<String, dynamic>{
        'requestId': widget.requestId,
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request reported successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to report: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReporting = false;
        });
      }
    }
  }

  void _openMap() async {
    if (widget.latitude != null && widget.longitude != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Move Car Request'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Someone requested you to move your car.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            
            if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) ...[
              const Text(
                'Photo Evidence:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.photoUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    color: Colors.grey[800],
                    child: const Center(child: Icon(Icons.image_not_supported, color: Colors.white54, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (widget.latitude != null && widget.longitude != null && widget.latitude!.isNotEmpty && widget.longitude!.isNotEmpty) ...[
              ElevatedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map),
                label: const Text('View Location on Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Okay, I will move it'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isReporting ? null : _reportFake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isReporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                          )
                        : const Text('Report as Fake'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
