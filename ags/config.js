const mpris = await Service.import('mpris');

const Media = () => Widget.Box({
    class_name: 'media-container',
    spacing: 10,
    children: [
        Widget.Button({
            class_name: 'media-btn',
            on_clicked: () => mpris.players[0]?.previous(),
            child: Widget.Label('⏮'),
        }),
        Widget.Button({
            class_name: 'media-btn',
            on_clicked: () => mpris.players[0]?.playPause(),
            child: Widget.Label().hook(mpris, label => {
                const player = mpris.players[0];
                label.label = player?.play_back_status === 'Playing' ? '⏸' : '▶';
            }),
        }),
        Widget.Button({
            class_name: 'media-btn',
            on_clicked: () => mpris.players[0]?.next(),
            child: Widget.Label('⏭'),
        }),
        Widget.Label({
            class_name: 'media-text',
        }).hook(mpris, label => {
            const player = mpris.players[0];
            label.label = player ? `${player.track_title} - ${player.track_artists.join(', ')}` : 'No Media Playing';
        }),
    ],
});

App.config({
    style: './style.css',
    windows: [
        Widget.Window({
            name: 'media_widget',
            anchor: ['bottom', 'left'],
            margins: [0, 0, 20, 20],
            layer: 'bottom',
            child: Media(),
        })
    ]
});