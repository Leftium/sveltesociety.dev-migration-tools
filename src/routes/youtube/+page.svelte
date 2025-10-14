<script lang="ts">
	import youtubeJson from '$lib/data/youtube.json';
	import playlistsJson from '$lib/data/playlists.json';
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';
	import FilterButtons from '$lib/components/FilterButtons.svelte';

	let checkedVideos = new SvelteSet<string>();
	let visibleIds = $state(new Set(youtubeJson.map((v) => v.id)));
	let showShorts = $state(false);
	let focusedTextarea = $state<string | null>(null);
	let textareaRefs: Record<string, HTMLElement> = {};
	let lastShiftKey = false;

	const shortsCount = $derived(youtubeJson.filter((v) => v.duration < 80 || v.ratio < 1).length);

	function getPlaylistsForVideo(videoId: string) {
		return playlistsJson.filter((playlist) => playlist.video_ids.includes(videoId));
	}

	const sortedVideos = $derived(
		youtubeJson.toSorted((a, b) => {
			const aIsShort = a.duration < 80 || a.ratio < 1;
			const bIsShort = b.duration < 80 || b.ratio < 1;

			if (aIsShort !== bIsShort) {
				return aIsShort ? -1 : 1;
			}

			const aPlaylists = getPlaylistsForVideo(a.id);
			const bPlaylists = getPlaylistsForVideo(b.id);

			const aHasPlaylist = aPlaylists.length > 0;
			const bHasPlaylist = bPlaylists.length > 0;

			if (aHasPlaylist !== bHasPlaylist) {
				return aHasPlaylist ? -1 : 1;
			}

			const aFirstPlaylist = aPlaylists[0]?.title || '';
			const bFirstPlaylist = bPlaylists[0]?.title || '';

			if (aFirstPlaylist !== bFirstPlaylist) {
				return aFirstPlaylist.localeCompare(bFirstPlaylist);
			}

			return b.timestamp - a.timestamp;
		})
	);

	onMount(() => {
		const stored = localStorage.getItem('checked-youtube');
		if (stored) {
			try {
				const parsed = JSON.parse(stored);
				parsed.forEach((id: string) => checkedVideos.add(id));
			} catch (err) {
				console.error('Failed to parse checked videos from localStorage:', err);
			}
		}
	});

	function autoSelect(node: HTMLTextAreaElement) {
		requestAnimationFrame(() => {
			const text = node.value;
			let blockStart = 0;
			const firstLineEnd = text.indexOf('\n');

			if (firstLineEnd !== -1) {
				const firstLine = text.substring(0, firstLineEnd).toLowerCase();
				if (
					firstLine.match(/^summary/i) ||
					firstLine.includes('sponsor') ||
					firstLine.includes('partner:')
				) {
					blockStart = firstLineEnd + 1;
				}
			}

			let blockEnd = text.indexOf('\n\n', blockStart);
			blockEnd = blockEnd === -1 ? text.length : blockEnd;

			node.focus();
			node.setSelectionRange(blockStart, blockEnd);
			const selectedText = text.substring(blockStart, blockEnd);
			navigator.clipboard.writeText(selectedText).catch((err) => {
				console.error('Failed to copy to clipboard:', err);
			});
		});
	}

	function handleCheckboxChange(youtubeId: string, checked: boolean, shiftKey: boolean) {
		if (checked) {
			checkedVideos.add(youtubeId);

			if (!shiftKey) {
				const videoUrl = `https://www.youtube.com/watch?v=${youtubeId}`;
				navigator.clipboard.writeText(videoUrl).catch((err) => {
					console.error('Failed to copy to clipboard:', err);
				});
				// window.open(videoUrl, 'YOUTUBE_VIDEO');

				const assistantParams = new URLSearchParams({
					q: `In 2-3 sentences, what is this video about? Don't mention "the video" or "this video" in your response. Use noun phrases instead of full sentences. Write in plain text only - no markdown, no links, no footnotes, no special formatting. ${videoUrl}`
				});

				const assistantUrl = `https://kagi.com/assistant?${assistantParams.toString()}`;
				window.open(assistantUrl, 'KAGI_ASSISTANT');

				const takeawayParams = new URLSearchParams({
					target_language: '',
					summary: 'takeaway',
					url: videoUrl
				});
				const takeawayUrl = `https://kagi.com/summarizer?${takeawayParams.toString()}`;
				window.open(takeawayUrl, 'KAGI_TAKEAWAY');

				const summaryParams = new URLSearchParams({
					target_language: '',
					summary: 'summary',
					url: videoUrl
				});
				const summaryUrl = `https://kagi.com/summarizer?${summaryParams.toString()}`;
				window.open(summaryUrl, 'KAGI_SUMMARY');
			}
		} else {
			checkedVideos.delete(youtubeId);
		}
		localStorage.setItem('checked-youtube', JSON.stringify(Array.from(checkedVideos)));
	}
</script>

{#if focusedTextarea}
	{@const video = youtubeJson.find((v) => v.id === focusedTextarea)}
	{@const textareaEl = textareaRefs[focusedTextarea]}
	{@const rect = textareaEl?.getBoundingClientRect()}
	<div class="overlay" onclick={() => (focusedTextarea = null)}></div>
	{#if video && rect}
		<textarea
			class="modal-textarea"
			readonly
			rows="20"
			value={video.description}
			style="top: {rect.top}px; left: {rect.left}px; width: {rect.width}px;"
			use:autoSelect
			onclick={(e) => {
				const start = e.currentTarget.selectionStart;
				const end = e.currentTarget.selectionEnd;

				if (start === end) {
					const text = e.currentTarget.value;
					const cursorPos = start;

					let blockStart = text.lastIndexOf('\n\n', cursorPos - 1);
					blockStart = blockStart === -1 ? 0 : blockStart + 2;

					const firstLineEnd = text.indexOf('\n');
					if (blockStart === 0 && firstLineEnd !== -1) {
						const firstLine = text.substring(0, firstLineEnd).toLowerCase();
						if (
							firstLine.match(/^summary/i) ||
							firstLine.includes('sponsor') ||
							firstLine.includes('partner:')
						) {
							blockStart = firstLineEnd + 1;
						}
					}

					let blockEnd = text.indexOf('\n\n', cursorPos);
					blockEnd = blockEnd === -1 ? text.length : blockEnd;

					e.currentTarget.setSelectionRange(blockStart, blockEnd);
					const selectedText = text.substring(blockStart, blockEnd);
					navigator.clipboard.writeText(selectedText).catch((err) => {
						console.error('Failed to copy to clipboard:', err);
					});
				}
			}}
			onselect={(e) => {
				const start = e.currentTarget.selectionStart;
				const end = e.currentTarget.selectionEnd;
				const selectedText = e.currentTarget.value.substring(start, end);
				if (selectedText) {
					navigator.clipboard.writeText(selectedText).catch((err) => {
						console.error('Failed to copy to clipboard:', err);
					});
				}
			}}
		></textarea>
	{/if}
{/if}

<div class="controls">
	<FilterButtons
		allItems={sortedVideos.map((v) => v.id)}
		checkedItems={checkedVideos}
		onFilterChange={(set) => (visibleIds = set)}
	/>
	<label>
		<input type="checkbox" bind:checked={showShorts} />
		Shorts ({shortsCount})
	</label>
</div>

<div class="grid-container">
	{#each sortedVideos as video, index}
		{@const isShort = video.duration < 80 || video.ratio < 1}
		{@const minutes = Math.floor(video.duration / 60)}
		{@const seconds = Math.floor(video.duration % 60)}
		{@const durationStr = `${minutes}:${seconds.toString().padStart(2, '0')}`}
		{@const playlists = getPlaylistsForVideo(video.id)}
		<div class="grid-row" class:hidden={!visibleIds.has(video.id) || (!showShorts && isShort)}>
			<div class="repo">
				<div class="index-wrapper">
					{index + 1}{#if isShort}📱{/if}
				</div>
				<a href={`https://www.youtube.com/watch?v=${video.id}`} target="_blank">{video.id}</a>
				<div class="meta">ratio: {video.ratio.toFixed(2)}</div>
				<div class="meta">length: {durationStr}</div>
			</div>
			<div class="description-column">
				<div class="title-wrapper">
					<input
						type="checkbox"
						id="video-{video.id}"
						checked={checkedVideos.has(video.id)}
						onclick={(e) => {
							lastShiftKey = e.shiftKey;
						}}
						onchange={(e) => handleCheckboxChange(video.id, e.currentTarget.checked, lastShiftKey)}
					/>
					<label
						for="video-{video.id}"
						class="title"
						onclick={(e) => {
							lastShiftKey = e.shiftKey;
							const input = document.getElementById(`video-${video.id}`) as HTMLInputElement;
							if (input) {
								input.checked = !input.checked;
								handleCheckboxChange(video.id, input.checked, e.shiftKey);
								e.preventDefault();
							}
						}}
					>
						{video.title}
					</label>
				</div>
				{#if playlists.length > 0}
					<div class="playlists">
						{playlists.map((p) => p.title).join(' • ')}
					</div>
				{/if}
				<div class="textarea-wrapper" bind:this={textareaRefs[video.id]}>
					<textarea
						class="description"
						readonly
						rows="3"
						value={video.description}
						onfocus={(e) => {
							e.currentTarget.blur();

							const textareaEl = textareaRefs[video.id];
							if (textareaEl) {
								const rect = textareaEl.getBoundingClientRect();
								const modalHeight = 20 * 30;
								const viewportHeight = window.innerHeight;
								const bottomOverflow = rect.top + modalHeight - viewportHeight;

								if (bottomOverflow > 0) {
									window.scrollBy({
										top: bottomOverflow + 100,
										behavior: 'smooth'
									});
									setTimeout(() => {
										focusedTextarea = video.id;
									}, 400);
								} else {
									focusedTextarea = video.id;
								}
							} else {
								focusedTextarea = video.id;
							}
						}}
					></textarea>
				</div>
			</div>
		</div>
	{/each}
</div>

<style>
	.controls {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.grid-container {
		display: grid;
		gap: 0;
	}

	.grid-row {
		display: grid;
		grid-template-columns: auto 1fr;
		gap: 1rem;
		align-items: start;
		border-bottom: 1px solid var(--pico-muted-border-color);
		padding: 0.5rem 0;
	}

	.grid-row:last-child {
		border-bottom: none;
	}

	.repo {
		padding-left: 0.5rem;
		font-family: monospace;
	}

	.index-wrapper {
		color: var(--pico-muted-color);
		font-variant-numeric: tabular-nums;
		font-size: 0.85em;
		margin-bottom: 0.5rem;
		padding-top: 3.25rem;
	}

	.meta {
		font-size: 0.85em;
		color: var(--pico-muted-color);
		margin-top: 0.25rem;
	}

	.description-column {
		padding-left: 1rem;
	}

	.title-wrapper {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.textarea-wrapper {
		position: relative;
	}

	.title {
		font-weight: 500;
		cursor: pointer;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		flex: 1;
	}

	.playlists {
		font-size: 0.85em;
		color: var(--pico-muted-color);
		margin-bottom: 0.5rem;
		margin-left: 2.25rem;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.description {
		cursor: pointer;
		resize: vertical;
		width: 100%;
	}

	.overlay {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.5);
		z-index: 9;
	}

	.modal-textarea {
		position: fixed;
		z-index: 10;
		cursor: pointer;
		resize: vertical;
		box-shadow: 0 8px 16px rgba(0, 0, 0, 0.5);
	}

	.hidden {
		display: none;
	}
</style>
