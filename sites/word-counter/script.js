const textInput = document.getElementById('text-input');
const wordCount = document.getElementById('word-count');

textInput.addEventListener('input', countWords);

function countWords() {
    const text = textInput.value.trim();
    const words = text ? text.split(/\s+/).length : 0;
    wordCount.textContent = `Words: ${words}`;
}