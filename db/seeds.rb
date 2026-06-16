AdminUser.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "admin@storefront.dev")) do |u|
  u.password = ENV.fetch("ADMIN_PASSWORD", "password123")
  u.password_confirmation = ENV.fetch("ADMIN_PASSWORD", "password123")
end

products = [
  { name: "Classic T-Shirt",     price: 24.99, description: "100% cotton, available in all sizes.", image_url: "https://placehold.co/300x400?text=T-Shirt" },
  { name: "Enamel Pin",          price: 8.99,  description: "Hard enamel, 1.5\" size, rubber clutch.", image_url: "https://placehold.co/300x300?text=Pin" },
  { name: "Art Poster 18x24",    price: 22.00, description: "Glossy print on 100lb paper.", image_url: "https://placehold.co/300x400?text=Poster" },
  { name: "Tote Bag",            price: 18.00, description: "Natural canvas, screen-printed.", image_url: "https://placehold.co/300x300?text=Tote" },
  { name: "Snapback Hat",        price: 32.00, description: "Structured 6-panel with flat brim.", image_url: "https://placehold.co/300x300?text=Hat" },
  { name: "Sticker Pack (5)",    price: 6.00,  description: "Weatherproof vinyl stickers.", image_url: "https://placehold.co/300x300?text=Stickers" },
  { name: "Long-Sleeve Shirt",   price: 34.99, description: "Midweight fleece, cozy fit.", image_url: "https://placehold.co/300x400?text=Long+Sleeve" },
  { name: "Vinyl Record",        price: 29.99, description: "180g black vinyl, inner sleeve.", image_url: "https://placehold.co/300x300?text=Vinyl" }
]

products.each do |attrs|
  Product.find_or_create_by!(name: attrs[:name]) do |p|
    p.price       = attrs[:price]
    p.description = attrs[:description]
    p.image_url   = attrs[:image_url]
  end
end

puts "Seeded #{Product.count} products and 1 admin user."
