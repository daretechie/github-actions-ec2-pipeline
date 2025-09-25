/* eslint-env browser */
document.addEventListener('DOMContentLoaded', () => {
  const productsContainer = document.getElementById('products');

  fetch('/api/products')
    .then((response) => response.json())
    .then((products) => {
      products.forEach((product) => {
        const productCard = `
          <div class="col-md-4">
            <div class="card">
              <div class="card-body">
                <h5 class="card-title">${product.name}</h5>
                <p class="card-text">$${product.price}</p>
              </div>
            </div>
          </div>
        `;
        productsContainer.innerHTML += productCard;
      });
    });
});
