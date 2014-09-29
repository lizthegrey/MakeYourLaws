class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, # :validatable, # do it better ourselves
         :encryptable, :confirmable, # :async,
         :lockable, :timeoutable, :omniauthable,
         authentication_keys: [:email] # :login_or_email, :email, :login, :name]
  rolify # :after_add => :after_role_add, :after_remove => :after_role_remove
  # resourcify  # Currently broken. https://github.com/EppO/rolify/issues/102
  has_many :users_roles
  has_many :roles, through: :users_roles

  has_many :identities
  has_many :carts
  has_one :current_cart, -> { where(state: [:empty, :filled, :checked_out]) }, class_name: 'Cart'

  extend FriendlyId
  friendly_id :email

  attr_accessor :strength_mock # login_or_email

  has_paper_trail
  strip_attributes

  validates :email, uniqueness: true, email: true, presence: true
  validates :name, presence: true # :login
  validates :login, uniqueness: true, allow_nil: true # login still unique pending move to profiles

  # No more logins for users. Only for profiles.
  validates :login, format: { with: /\A[a-zA-Z0-9_]+\z/i,
    message: 'can only have letters a-z, digits and underscores' }, allow_nil: true
  validates :login, format: { with: /\A[a-zA-Z0-9].*\z/i,
    message: 'must start with letter or digit' }, allow_nil: true
  validates :login, format: { with: /\A.*[a-zA-Z0-9]\z/i,
    message: 'must end with letter or digit' }, allow_nil: true

  validates :password, format: { with: /\A.*[[:alpha:]].*\z/,
    message: 'must contain at least one letter' }, if: :password_required?
  # Note: :punct: is supposed to match all punctuation, but misses =`~$^+|<>> - see http://stackoverflow.com/questions/11130490/why-does-ruby-punct-miss-some-punctuation-characters
  validates :password, format:  { with: /\A.*[[:digit:]\s[:punct:]=`~$^+|<>>].*\z/,
                       message: 'must contain a number, space, or punctuation character' },
                       if:      :password_required?
  validates :password, length: { minimum: 6 }, if: :password_required?

  before_validation do
    login.downcase! if login
  end

  validate :validate_password_strength

  scope :dau, ->(date) { where(updated_at: (date.midnight .. (date + 1).midnight)) }

  def validate_password_strength
    # only set if setting the password; it's stored as encrypted_password
    return true unless password_required?

    errors.add :password_confirmation, 'must match' unless password == password_confirmation

    unless strength_mock # prevent recursion
      password_excerpt = password.gsub(/(#{email}|#{name})/i, '')
      if password_excerpt != password
        mock =  User.new password: password_excerpt, password_confirmation: password_excerpt,
           login: login, email: email
        mock.strength_mock = true
        # Note: This errror message is actually lying a bit.
        # If your password is contains the email/name, but is strong by itself, that's OK.
        #  But not eg foobar/foobar1.
        unless mock.valid? || mock.errors[:password].blank?
          errors.add :password, 'must not contain email or name'
        end
      end
    end
    true
  end

  # def self.find_first_by_auth_conditions(tainted_conditions, opts={})
  #   conditions = tainted_conditions.dup
  #   login = conditions.delete(:login_or_email)
  #   if login
  #     if login =~ /@/
  #       conditions[:email] = login.strip.downcase
  #     else
  #       conditions[:login] = login.strip.downcase
  #     end
  #   end
  #   super conditions, opts
  # end

  def password_required?
    !(password.blank? && password_confirmation.blank? &&
      (persisted? || !identities.empty?))
  end

  def update_with_password params, *options
    current_password = params.delete(:current_password)

    if params[:password].blank?
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end

    result = if !password_required? || valid_password?(current_password)
               update_attributes(params, *options)
             else
               self.attributes = params
               self.valid?
               errors.add(:current_password, current_password.blank? ? :blank : :invalid)
               false
             end

    clean_up_passwords
    result
  end
end
