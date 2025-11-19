import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:railone/models/pnr.dart';
import 'package:railone/services/pnr_service.dart';

class PnrStatusScreen extends StatefulWidget {
  final String pnr;
  const PnrStatusScreen({super.key, required this.pnr});

  @override
  State<PnrStatusScreen> createState() => _PnrStatusScreenState();
}

class _PnrStatusScreenState extends State<PnrStatusScreen> {
  PnrRecord? _pnrRecord;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPnrStatus();
  }

  Future<void> _checkPnrStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Use PnrService to get data from Firebase
      final record = await PnrService.checkPnrStatus(widget.pnr);
      setState(() {
        _pnrRecord = record;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'waitlist':
        return Colors.orange;
      case 'rac':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTrainStatusColor(String status) {
    if (status.toLowerCase().contains('on time')) {
      return Colors.green;
    } else if (status.toLowerCase().contains('delay') || status.toLowerCase().contains('late')) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PNR: ${widget.pnr}'),
        actions: [
          IconButton(
            onPressed: _checkPnrStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkPnrStatus,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _pnrRecord == null
                  ? const Center(child: Text('PNR not found'))
                  : _buildPnrDetails(),
    );
  }

  Widget _buildPnrDetails() {
    final record = _pnrRecord!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journey Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.train, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${record.trainNumber} • ${record.trainName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.from, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Departure: ${record.departureTime}', style: const TextStyle(fontSize: 12)),
                            Text('Platform: ${record.platform}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(record.to, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Arrival: ${record.arrivalTime}', style: const TextStyle(fontSize: 12)),
                            Text('Coach Position: ${record.coachPosition}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusChip('Journey Date', record.journeyDate, Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusChip('Class', record.journeyClass, Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Train Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Train Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusChip(
                          'Status',
                          record.trainStatus,
                          _getTrainStatusColor(record.trainStatus),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatusChip(
                          'Chart',
                          record.chartStatus,
                          record.chartStatus == 'Chart Prepared' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Last Updated: ${DateFormat.yMMMd().add_jm().format(DateTime.parse(record.lastUpdated))}',
                       style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Booking Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailRow('PNR Number', record.pnr),
                  _buildDetailRow('Booking Date', record.bookingDate),
                  _buildDetailRow('Fare', '₹${record.fare}'),
                  if (record.quantity != null)
                    _buildDetailRow('Tickets', '${record.quantity}'),
                  if (record.ticketPrice != null)
                    _buildDetailRow('Ticket Price', '₹${record.ticketPrice}'),
                  _buildDetailRow('Quota', record.quota),
                  _buildDetailRow('Boarding Station', record.boardingStation),
                  _buildDetailRow('Destination Station', record.destinationStation),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Payment Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildPaymentTable(record),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Passengers Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Passengers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (record.passengers.isEmpty)
                    const Text('No passenger details available')
                  else
                    ...record.passengers.asMap().entries.map((e) {
                      final i = e.key + 1;
                      final p = e.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(child: Text('$i')),
                        title: Text('${p.name}  ·  ${p.gender}, ${p.age}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coach: ${p.coach}  •  Seat: ${p.seat} (${p.berth})'),
                            Text('Status: ${p.bookingStatus}  •  Current: ${p.currentStatus}'),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentTable(PnrRecord record) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Card Number', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Transaction ID', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Table Row
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    record.paymentMethod ?? 'N/A',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    record.cardNumber ?? 'N/A',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    record.transactionId ?? 'N/A',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPaymentStatusColor(record.paymentStatus ?? 'Unknown').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.paymentStatus ?? 'N/A',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPaymentStatusColor(record.paymentStatus ?? 'Unknown'),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    record.paymentDate ?? 'N/A',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

}
