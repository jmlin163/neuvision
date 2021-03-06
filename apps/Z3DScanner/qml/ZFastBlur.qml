import QtQuick 2.12

import QtGraphicalEffects 1.12

// This is just to avoid repeating code and makes it easier to use blur
// for things that are on top of another thing, blurring the right area of the
// source below this item itself
Item {
    id: root
    property alias source: effectSource.sourceItem
    property int radius: 64

    // Should be more efficient than using big radius in blur?
    // Also because using just radius 256 does not work in FastBlur.
    // If radius is really big we can subsample even more (1/4^2 vs 1/2^2),
    // but not if radius is smaller, because it takes too few samples and "flickers"
    property real _textureScale: radius > 128
                                 ? 0.25
                                 : radius > 64
                                   ? 0.5
                                   : 1

    property point sourcePosition: mapToItem(source, 0, 0)
    property rect sourceRect: Qt.rect(sourcePosition.x, sourcePosition.y, width, height)

    function updateSourceRect() {
        sourcePosition = mapToItem(source, 0, 0)
    }

    Component.onCompleted: {
        // a hack for getting updates every time this item global position changes
        let current = root;
        while (current && current.parent) {
            current.onXChanged.connect(updateSourceRect);
            current.onYChanged.connect(updateSourceRect);
            current = current.parent;
        }

        updateSourceRect();
    }

    ShaderEffectSource {
        id: effectSource
        anchors.fill: parent
        live: true
        visible: false
        wrapMode: ShaderEffectSource.Repeat
        sourceRect: root.sourceRect
        textureSize: Qt.size(_textureScale * width, _textureScale * height)
    }

    FastBlur {
        anchors.centerIn: parent // scale will be applied from center of item
        width: effectSource.width * _textureScale
        height: effectSource.height * _textureScale
        source: effectSource
        radius: root.radius * _textureScale
        scale: 1 / _textureScale
    }
}
