<script lang="ts">
	import youtubeJson from '$lib/data/youtube.json';
	import { onMount } from 'svelte';
	import { SvelteSet } from 'svelte/reactivity';
	import FilterButtons from '$lib/components/FilterButtons.svelte';

	let checkedVideos = new SvelteSet<string>();
	let visibleIds = $state(new Set(youtubeJson.map((v) => v.id)));

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

	function handleCheckboxChange(youtubeId: string, checked: boolean) {
		if (checked) {
			checkedVideos.add(youtubeId);
			const videoUrl = `https://www.youtube.com/watch?v=${youtubeId}`;
			navigator.clipboard.writeText(videoUrl).catch((err) => {
				console.error('Failed to copy to clipboard:', err);
			});
			window.open(videoUrl, 'YOUTUBE_VIDEO');

			const takeawayParams = new URLSearchParams({
				target_language: '',
				summary: 'takeaway',
				url: videoUrl
			});
			const takeawayUrl = `https://kagi.com/summarizer?${takeawayParams.toString()}`;
			window.open(takeawayUrl, 'KAGI_TAKEAWAY');

			const assistantParams = new URLSearchParams({
				q: `In 2-3 sentences, what is this video about? Don't mention "the video" or "this video" in your response. Use noun phrases instead of full sentences. Write in plain text only - no markdown, no links, no footnotes, no special formatting. ${videoUrl}`
			});
			const assistantUrl = `https://kagi.com/assistant?${assistantParams.toString()}`;
			window.open(assistantUrl, 'KAGI_ASSISTANT');

			const summaryParams = new URLSearchParams({
				target_language: '',
				summary: 'summary',
				url: videoUrl
			});
			const summaryUrl = `https://kagi.com/summarizer?${summaryParams.toString()}`;
			window.open(summaryUrl, 'KAGI_SUMMARY');
		} else {
			checkedVideos.delete(youtubeId);
		}
		localStorage.setItem('checked-youtube', JSON.stringify(Array.from(checkedVideos)));
	}
</script>

<FilterButtons
	allItems={youtubeJson.map((v) => v.id)}
	checkedItems={checkedVideos}
	onFilterChange={(set) => (visibleIds = set)}
/>

<div class="grid-container">
	{#each youtubeJson as video, index}
		<div class="grid-row" class:hidden={!visibleIds.has(video.id)}>
			<div class="index">{index + 1}</div>
			<div class="checkbox">
				<input
					type="checkbox"
					checked={checkedVideos.has(video.id)}
					onchange={(e) => handleCheckboxChange(video.id, e.currentTarget.checked)}
				/>
			</div>
			<div class="repo">
				<a href={`https://www.youtube.com/watch?v=${video.id}`} target="_blank">{video.id}</a>
			</div>
			<textarea
				class="description"
				readonly
				rows="3"
				value={video.description}
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
				onfocus={(e) => {
					e.currentTarget.rows = 10;
					const text = e.currentTarget.value;

					let startIndex = 0;
					const firstLineEnd = text.indexOf('\n');
					if (firstLineEnd !== -1) {
						const firstLine = text.substring(0, firstLineEnd).toLowerCase();
						if (
							firstLine.match(/^summary/i) ||
							firstLine.includes('sponsor') ||
							firstLine.includes('partner:')
						) {
							startIndex = firstLineEnd + 1;
						}
					}

					let endIndex = text.indexOf('\n\n', startIndex);
					if (endIndex === -1) {
						endIndex = text.length;
					}

					e.currentTarget.setSelectionRange(startIndex, endIndex);
					const selectedText = text.substring(startIndex, endIndex);
					navigator.clipboard.writeText(selectedText).catch((err) => {
						console.error('Failed to copy to clipboard:', err);
					});
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
				onblur={(e) => (e.currentTarget.rows = 3)}
			></textarea>
		</div>
	{/each}
</div>

<style>
	.grid-container {
		display: grid;
		gap: 0;
	}

	.grid-row {
		display: grid;
		grid-template-columns: 4rem 3rem 10rem 1fr;
		align-items: start;
		border-bottom: 1px solid var(--pico-muted-border-color);
		padding: 0.5rem 0;
	}

	.grid-row:last-child {
		border-bottom: none;
	}

	.index {
		text-align: right;
		padding-right: 1rem;
		color: var(--pico-muted-color);
		font-variant-numeric: tabular-nums;
	}

	.checkbox {
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.repo {
		padding-left: 0.5rem;
		font-family: monospace;
	}

	.description {
		padding-left: 1rem;
		cursor: pointer;
		resize: vertical;
	}

	.hidden {
		display: none;
	}
</style>
