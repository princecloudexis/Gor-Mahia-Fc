import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

class SafeSvgNetwork extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final ColorFilter? colorFilter;
  final WidgetBuilder? placeholderBuilder;

  const SafeSvgNetwork(
    this.url, {
    Key? key,
    this.width,
    this.height,
    this.colorFilter,
    this.placeholderBuilder,
  }) : super(key: key);

  @override
  State<SafeSvgNetwork> createState() => _SafeSvgNetworkState();
}

class _SafeSvgNetworkState extends State<SafeSvgNetwork> {
  String? _svgString;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }
  
  @override
  void didUpdateWidget(SafeSvgNetwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(widget.url));
      
      // If it's a 404 or not an SVG (e.g. HTML 404 page), mark as error
      if (response.statusCode != 200 || !response.body.trimLeft().startsWith(RegExp(r'<[a-zA-Z?]'))) {
        if (mounted) setState(() => _hasError = true);
        return;
      }
      
      if (mounted) {
        setState(() {
          _svgString = response.body;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.placeholderBuilder?.call(context) ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Icon(Icons.broken_image_outlined, size: 16, color: Colors.grey),
          );
    }

    if (_isLoading || _svgString == null) {
      return widget.placeholderBuilder?.call(context) ?? 
             SizedBox(width: widget.width, height: widget.height);
    }

    return SvgPicture.string(
      _svgString!,
      width: widget.width,
      height: widget.height,
      colorFilter: widget.colorFilter,
    );
  }
}
